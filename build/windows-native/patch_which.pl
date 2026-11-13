use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
my $add = <<'LUME';
## ---- PATH lookup -------------------------------------------------------------------------------------------
## the entries of $PATH (":" on Linux; ";" on Windows, where entries are "C:\..." and become POSIX paths)
fn hio_sep_end(s, i, sep) = if i >= count(s) or at(s, i) == sep then i else hio_sep_end(s, i + 1, sep)
fn hio_split(s, i, sep) = if i >= count(s) then Nil else let e = hio_sep_end(s, i, sep) in if e == i then hio_split(s, i + 1, sep) else Cons(hio_posix(slice(s, i, e)), hio_split(s, e + 1, sep))
fn hio_path_dirs() = let w = os_platform() == "windows" in let p = os_getenv("PATH") in let q = if p != "" then p else os_getenv("Path") in hio_split(q, 0, if w then ";" else ":")
fn hio_which_in(dirs, name) = match dirs
    Nil        => ""
    Cons(h, t) => let p = hio_trim_end(h) + "/" + name in if fs_path_exists(p + ".exe") == 1 and not hio_is_dir(p + ".exe") then p + ".exe" else if fs_path_exists(p) == 1 and not hio_is_dir(p) then p else hio_which_in(t, name)
## the program file `name` resolves to through $PATH, or ""
fn hio_which(name) = hio_which_in(hio_path_dirs(), name)
## an absolute program path that does not exist on this host (e.g. /usr/bin/z3 on Windows) is looked up by name
fn hio_resolve(prog) = if fs_path_exists(prog) == 1 or fs_path_exists(prog + ".exe") == 1 or (not hio_prefix(prog, "/usr/bin/") and not hio_prefix(prog, "/bin/") and not hio_prefix(prog, "/usr/local/bin/")) then prog else let w = hio_which(hio_base(prog)) in if w != "" then w else prog

LUME
my $a = '## drop-in replacements of the process builtins';
my $i = index($t, $a); die "a" if $i < 0; substr($t, $i, 0) = $add;
# route the real starts through hio_resolve
my $n = 0;
$n += ($t =~ s/else os_run\(prog, args\)/else os_run(hio_resolve(prog), args)/);
$n += ($t =~ s/else os_run_capture\(prog, args, out, err\)/else os_run_capture(hio_resolve(prog), args, out, err)/);
$n += ($t =~ s/else os_run_capture_timeout\(prog, args, out, err, ms\)/else os_run_capture_timeout(hio_resolve(prog), args, out, err, ms)/);
$n += ($t =~ s/else os_run_input_capture_timeout\(prog, args, inp, out, err, ms\)/else os_run_input_capture_timeout(hio_resolve(prog), args, inp, out, err, ms)/);
die "routes $n" unless $n == 4;
$t =~ s/(fn test_hio_uname_sysname\(\) = .*\n)/$1fn test_hio_resolve_keeps_existing_and_relative() = hio_resolve("build") == "build" and hio_resolve("\/usr\/bin\/lume-never-installed-xyz") == "\/usr\/bin\/lume-never-installed-xyz" and count(hio_path_dirs()) > 0\n/ or die "t";
open my $o, '>:raw', $f or die; print $o $t; close $o; print "which added\n";

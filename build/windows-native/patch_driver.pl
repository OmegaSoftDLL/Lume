# Patch compiler/stage1/lume_driver.src for the native Windows host (exact substitutions, each must apply once or more).
# - external /bin/cp, /bin/mv, /bin/rm, /bin/chmod become the runtime builtins fs_copy, fs_rename, fs_remove,
#   fs_make_executable (same behaviour on Linux and Windows);
# - tool lookups accept "<name>.exe";
# - the quiet test runner, which used /bin/sh -c 'cd root && binary', changes directory itself on Windows.
use strict; use warnings;
local $/;
my $f = shift;
open my $in, '<:raw', $f or die "$f: $!";
my $t = <$in>;
close $in;
my $total = 0;
sub rep {
  my ($old, $new, $min) = @_;
  my $n = 0;
  my $pos = 0;
  while ((my $i = index($t, $old, $pos)) >= 0) {
    substr($t, $i, length($old)) = $new;
    $pos = $i + length($new);
    $n++;
  }
  die "pattern applied $n times (expected >= $min): $old\n" if $n < $min;
  $total += $n;
}
rep('os_run_capture_timeout("/bin/cp", Cons("-f", Cons(bp, Cons(tmp, Nil))), "/dev/null", "/dev/null", 30000)',
    '(if fs_copy(bp, tmp) == 1 then 0 else 1)', 1);
rep('os_run_capture_timeout("/bin/cp", Cons("-f", Cons(out, Cons(tmp, Nil))), "/dev/null", "/dev/null", 30000)',
    '(if fs_copy(out, tmp) == 1 then 0 else 1)', 1);
rep('os_run_capture_timeout("/bin/chmod", Cons("+x", Cons(tmp, Nil)), "/dev/null", "/dev/null", 30000)',
    '(if fs_make_executable(tmp) == 1 then 0 else 1)', 2);
rep('os_run("/bin/chmod", Cons("+x", Cons(out, Nil)))', '(if fs_make_executable(out) == 1 then 0 else 1)', 1);
rep('os_run("/bin/chmod", Cons("+x", Cons(binary, Nil)))', '(if fs_make_executable(binary) == 1 then 0 else 1)', 1);
rep('let z = os_run("/bin/rm", Cons("-f", Cons(b.path, Nil))) in', 'let z = ld_remove_if_present(b.path) in', 1);
rep('else os_run("/bin/rm", Cons("-f", Cons(h.path, Nil))) in', 'else (if ld_remove_if_present(h.path) == 1 then 0 else 1) in', 1);
rep('fn ld_cache_publish(tmp, path) = if fs_path_exists("/bin/mv") == 1 then (if os_run_capture_timeout("/bin/mv", Cons("-f", Cons(tmp, Cons(path, Nil))), "/dev/null", "/dev/null", 30000) == 0 then 1 else let z = fs_remove(tmp) in 0) else let c = os_run_capture_timeout("/bin/cp", Cons("-f", Cons(tmp, Cons(path, Nil))), "/dev/null", "/dev/null", 30000) in let z = fs_remove(tmp) in if c == 0 then 1 else 0',
    "## publish tmp as path: an atomic rename, else (another file system) a copy; tmp is gone afterwards\nfn ld_cache_publish(tmp, path) = if fs_rename(tmp, path) == 1 then 1 else let c = fs_copy(tmp, path) in let z = fs_remove(tmp) in c", 1);
rep('fn ld_tool(root, name) = let b = root + "/build/bin/" + name in if fs_path_exists(b) == 1 then b else root + "/bin/" + name',
    "## a tool exists as <path> (Linux) or <path>.exe (Windows); the process layer starts either from <path>\nfn ld_exists_bin(p) = if fs_path_exists(p) == 1 then 1 else fs_path_exists(p + \".exe\")\nfn ld_tool(root, name) = let b = root + \"/build/bin/\" + name in if ld_exists_bin(b) == 1 then b else root + \"/bin/\" + name", 1);
for my $p ('"build/bin/lumec"', '"bin/lumec"', '"../build/bin/lumec"', '"../bin/lumec"', 'root + "/build/bin/lsha"', 'root + "/bin/lsha"', 'root + "/build/bin/lume_driver"') {
  rep("fs_path_exists($p)", "ld_exists_bin($p)", 1);
}
rep('os_run_capture_timeout("/bin/sh", Cons("-c", Cons("cd \"" + root + "\" && " + (if ld_test_serial(g.btext, 1) == 1 then "/usr/bin/flock " + ld_test_lock() + " " else "") + "\"" + binary + "\"", Nil)), stem + ".out", stem + ".err", 1800000)',
    '(if os_platform() == "windows" then ld_run_in_dir(root, binary, stem + ".out", stem + ".err") else os_run_capture_timeout("/bin/sh", Cons("-c", Cons("cd \"" + root + "\" && " + (if ld_test_serial(g.btext, 1) == 1 then "/usr/bin/flock " + ld_test_lock() + " " else "") + "\"" + binary + "\"", Nil)), stem + ".out", stem + ".err", 1800000))', 1);
rep('fn ld_test_quiet(root, source) =',
    "## Windows has no /bin/sh: run the binary with root as the current directory, then restore it\nfn ld_run_in_dir(root, binary, out, err) = let here = fs_current_dir() in let moved = fs_chdir(root) in let st = os_run_capture_timeout(binary, Nil, out, err, 1800000) in let back = fs_chdir(here) in st\nfn ld_test_quiet(root, source) =", 1);
open my $o, '>:raw', $f or die;
print $o $t;
close $o;
print "driver patched: $total substitutions\n";

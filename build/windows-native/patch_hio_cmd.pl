use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
my $add = <<'LUME';
## ---- command lines --------------------------------------------------------------------------------------------
## a configured command line runs without a shell when it is only words (quotes allowed); one with shell syntax
## (pipes, redirection, groups, variables, globs) goes to the host's sh: /bin/sh, or sh found through $PATH
fn hio_meta(c) = c == "|" or c == "&" or c == ";" or c == "<" or c == ">" or c == "(" or c == ")" or c == "{" or c == "}" or c == "$" or c == "`" or c == "*" or c == "?" or c == "\n" or c == "~"
fn hio_has_meta(s, i) = if i >= count(s) then 0 else if hio_meta(at(s, i)) then 1 else hio_has_meta(s, i + 1)
## words of a command line: blanks separate, '...' and "..." quote (a backslash quotes the next byte outside '...')
fn hio_words_go(s, i, cur, has, q, acc) = if i >= count(s) then (if has == 1 then hio_rev(Cons(cur, acc), Nil) else hio_rev(acc, Nil)) else let c = at(s, i) in if q == "" and (c == " " or c == "\t") then hio_words_go(s, i + 1, "", 0, "", if has == 1 then Cons(cur, acc) else acc) else if q == "" and (c == "'" or c == "\"") then hio_words_go(s, i + 1, cur, 1, c, acc) else if q != "" and c == q then hio_words_go(s, i + 1, cur, 1, "", acc) else if c == "\\" and q != "'" and i + 1 < count(s) then hio_words_go(s, i + 2, cur + at(s, i + 1), 1, q, acc) else hio_words_go(s, i + 1, cur + c, 1, q, acc)
fn hio_rev(xs, acc) = match xs
    Nil        => acc
    Cons(h, t) => hio_rev(t, Cons(h, acc))
fn hio_words(s) = hio_words_go(s, 0, "", 0, "", Nil)
fn hio_sh() = if fs_path_exists("/bin/sh") == 1 then "/bin/sh" else hio_which("sh")
fn hio_cmd_words(ws, inp, out, err, ms) = match ws
    Nil        => 256
    Cons(p, a) => hio_osrun_ict(p, a, inp, out, err, ms)
## run command line `cmd` with stdin from inp, stdout/stderr to out/err, killed after ms milliseconds
fn hio_cmdline_ict(cmd, inp, out, err, ms) = if hio_has_meta(cmd, 0) == 0 then hio_cmd_words(hio_words(cmd), inp, out, err, ms) else let sh = hio_sh() in if sh == "" then (let w = fs_write_sync(err, "no sh on this host for: " + cmd + "\n") in 32512) else os_run_input_capture_timeout(sh, Cons("-c", Cons(cmd, Nil)), inp, out, err, ms)

LUME
my $a = '## drop-in replacements of the process builtins';
my $i = index($t, $a); die "a" if $i < 0; substr($t, $i, 0) = $add;
# the input-capture dispatcher resolves programs through PATH too and does known programs in Lume
$t =~ s/else os_run_input_capture_timeout\(hio_resolve\(prog\), args, inp, out, err, ms\)/else let n = hio_emulated(prog) in if n != "" then hio_run_capture(n, args, out, err) else os_run_input_capture_timeout(hio_resolve(prog), args, inp, out, err, ms)/ or die "ict";
$t =~ s/(fn test_hio_resolve_keeps_existing_and_relative\(\) = .*\n)/$1fn test_hio_command_words() = let w = hio_words("prog -a 'two words' \\"x y\\" z\\ w") in count(w) == 5 and hio_first(w, "") == "prog" and hio_has_meta("qemu-riscv64 -L . ch.elf", 0) == 0 and hio_has_meta("sed s\/a\/b\/ | x", 0) == 1\n/ or die "t";
open my $o, '>:raw', $f or die; print $o $t; close $o; print "cmdline added\n";

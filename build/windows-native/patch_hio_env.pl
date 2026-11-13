use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
my $old = '## drop-in replacements of the process builtins: known programs run here, every other one is started as before
fn hio_osrun(prog, args) = let n = hio_emulated(prog) in if n != "" then hio_run(n, args) else os_run(prog, args)
fn hio_osrun_c(prog, args, out, err) = let n = hio_emulated(prog) in if n != "" then hio_run_capture(n, args, out, err) else os_run_capture(prog, args, out, err)
fn hio_osrun_ct(prog, args, out, err, ms) = let n = hio_emulated(prog) in if n != "" then hio_run_capture(n, args, out, err) else os_run_capture_timeout(prog, args, out, err, ms)';
my $new = '## ---- env NAME=VALUE ... program args: the assignments hold for that program only ------------------------------
fn hio_eq_at(a, i) = if i >= count(a) then 0 - 1 else if at(a, i) == "=" then i else hio_eq_at(a, i + 1)
fn hio_is_assign(a) = hio_eq_at(a, 0) > 0
fn hio_assigns(args) = match args
    Nil        => Nil
    Cons(h, t) => if hio_is_assign(h) then Cons(h, hio_assigns(t)) else Nil
fn hio_after_assigns(args) = match args
    Nil        => Nil
    Cons(h, t) => if hio_is_assign(h) then hio_after_assigns(t) else args
fn hio_tail(xs) = match xs
    Nil        => Nil
    Cons(h, t) => t
## set each NAME=VALUE; the list returned holds what to put back ({name, old}; old "" = was not set)
fn hio_env_apply(xs) = match xs
    Nil        => Nil
    Cons(h, t) => let i = hio_eq_at(h, 0) in let name = slice(h, 0, i) in let old = os_getenv(name) in let s = os_setenv(name, slice(h, i + 1, count(h))) in Cons({name: name, old: old}, hio_env_apply(t))
fn hio_env_restore(xs) = match xs
    Nil        => 1
    Cons(h, t) => let r = hio_env_restore(t) in if h.old == "" then os_unsetenv(h.name) else os_setenv(h.name, h.old)
fn hio_with_env(args, run) = let saved = hio_env_apply(hio_assigns(args)) in let rest = hio_after_assigns(args) in let r = (match rest
    Nil        => 0
    Cons(p, a) => run(p, a)) in let z = hio_env_restore(saved) in r
## drop-in replacements of the process builtins: known programs run here, every other one is started as before
fn hio_osrun(prog, args) = if prog == "/usr/bin/env" then hio_with_env(args, fn(p, a) => hio_osrun(p, a)) else let n = hio_emulated(prog) in if n != "" then hio_run(n, args) else os_run(prog, args)
fn hio_osrun_c(prog, args, out, err) = if prog == "/usr/bin/env" then hio_with_env(args, fn(p, a) => hio_osrun_c(p, a, out, err)) else let n = hio_emulated(prog) in if n != "" then hio_run_capture(n, args, out, err) else os_run_capture(prog, args, out, err)
fn hio_osrun_ct(prog, args, out, err, ms) = if prog == "/usr/bin/env" then hio_with_env(args, fn(p, a) => hio_osrun_ct(p, a, out, err, ms)) else let n = hio_emulated(prog) in if n != "" then hio_run_capture(n, args, out, err) else os_run_capture_timeout(prog, args, out, err, ms)
## os_run_input_capture_timeout with the same routing (env, known programs)
fn hio_osrun_ict(prog, args, inp, out, err, ms) = if prog == "/usr/bin/env" then hio_with_env(args, fn(p, a) => hio_osrun_ict(p, a, inp, out, err, ms)) else os_run_input_capture_timeout(prog, args, inp, out, err, ms)';
my $i = index($t, $old); die "nf" if $i < 0; substr($t, $i, length($old)) = $new;
$t =~ s/(fn test_hio_home_is_posix\(\) = .*\n)/$1fn test_hio_env_scoped() = let before = os_getenv("LUME_HIO_PROBE") in let r = hio_with_env(Cons("LUME_HIO_PROBE=on", Cons("x", Nil)), fn(p, a) => if os_getenv("LUME_HIO_PROBE") == "on" then 0 else 256) in r == 0 and os_getenv("LUME_HIO_PROBE") == before\nfn test_hio_setenv_unsetenv() = os_setenv("LUME_HIO_X", "1") == 1 and os_getenv("LUME_HIO_X") == "1" and os_setenv("LUME_HIO_X", "2") == 1 and os_getenv("LUME_HIO_X") == "2" and os_unsetenv("LUME_HIO_X") == 1 and os_getenv("LUME_HIO_X") == "" and os_setenv("A=B", "x") == 0 and os_setenv("", "x") == 0\n/ or die "t";
open my $o, '>:raw', $f or die; print $o $t; close $o; print "env emulation added\n";

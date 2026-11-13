use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
my $add = <<'LUME';
## ---- date and uname -----------------------------------------------------------------------------------------
## days since 1970-01-01 -> {y, m, d} (proleptic Gregorian; the civil-from-days method)
fn hio_civil(days) = let z = days + 719468 in let era = (if z >= 0 then z else z - 146096) / 146097 in let doe = z - era * 146097 in let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365 in let doy = doe - (365 * yoe + yoe / 4 - yoe / 100) in let mp = (5 * doy + 2) / 153 in let d = doy - (153 * mp + 2) / 5 + 1 in let m = if mp < 10 then mp + 3 else mp - 9 in {y: yoe + era * 400 + (if m <= 2 then 1 else 0), m: m, d: d}
fn hio_pad2(n) = if n < 10 then "0" + str(n) else str(n)
fn hio_nth(names, i) = slice(names, i * 3, i * 3 + 3)
fn hio_wday(days) = ((days % 7) + 11) % 7
## strftime for the fields the tools use: %Y %m %d %H %M %S %s %a %b %e %Z %T %F %%; the clock is UTC
fn hio_strf(fmt, i, t, acc) = if i >= count(fmt) then acc else if at(fmt, i) != "%" or i + 1 >= count(fmt) then hio_strf(fmt, i + 1, t, acc + at(fmt, i)) else hio_strf(fmt, i + 2, t, acc + hio_field(at(fmt, i + 1), t))
fn hio_field(c, t) = let days = (if t >= 0 then t else t - 86399) / 86400 in let s = t - days * 86400 in let cv = hio_civil(days) in if c == "Y" then str(cv.y) else if c == "m" then hio_pad2(cv.m) else if c == "d" then hio_pad2(cv.d) else if c == "e" then (if cv.d < 10 then " " + str(cv.d) else str(cv.d)) else if c == "H" then hio_pad2(s / 3600) else if c == "M" then hio_pad2(s % 3600 / 60) else if c == "S" then hio_pad2(s % 60) else if c == "s" then str(t) else if c == "a" then hio_nth("SunMonTueWedThuFriSat", hio_wday(days)) else if c == "b" then hio_nth("JanFebMarAprMayJunJulAugSepOctNovDec", cv.m - 1) else if c == "Z" then "UTC" else if c == "T" then hio_field("H", t) + ":" + hio_field("M", t) + ":" + hio_field("S", t) else if c == "F" then hio_field("Y", t) + "-" + hio_field("m", t) + "-" + hio_field("d", t) else if c == "%" then "%" else "%" + c
fn hio_fmt_arg(args) = match args
    Nil        => "%a %b %e %T %Z %Y"
    Cons(h, t) => if count(h) >= 1 and at(h, 0) == "+" then slice(h, 1, count(h)) else hio_fmt_arg(t)
fn hio_date(args) = {ok: 1, out: hio_strf(hio_fmt_arg(args), 0, os_unix_time(), "") + "\n"}
fn hio_uname_pick(fl, c, i) = if hio_has(fl, c, 0) == 1 or hio_has(fl, "a", 0) == 1 then Cons(os_uname_field(i), Nil) else Nil
fn hio_join_sp(xs) = match xs
    Nil          => ""
    Cons(h, Nil) => h
    Cons(h, t)   => h + " " + hio_join_sp(t)
fn hio_cat(a, b) = match a
    Nil        => b
    Cons(h, t) => Cons(h, hio_cat(t, b))
fn hio_uname(fl) = let f = if fl == "" then "s" else fl in {ok: 1, out: hio_join_sp(hio_cat(hio_uname_pick(f, "s", 0), hio_cat(hio_uname_pick(f, "n", 1), hio_cat(hio_uname_pick(f, "r", 2), hio_cat(hio_uname_pick(f, "v", 3), hio_uname_pick(f, "m", 4)))))) + "\n"}

LUME
$t =~ s/(## the work of one program: \{ok, out\})/$add$1/ or die "a";
my $pw = 'else if prog == "pwd" then {ok: 1, out: fs_current_dir() + "' . chr(92) . 'n"}'; my $pi = index($t, $pw); die "b" if $pi < 0; substr($t, $pi + length($pw), 0) = q{ else if prog == "date" then hio_date(args) else if prog == "uname" then hio_uname(fl)};
$t =~ s/or n == "ls" or n == "pwd" or/or n == "ls" or n == "pwd" or n == "date" or n == "uname" or/ or die "c";
$t =~ s/(fn test_hio_setenv_unsetenv\(\) = .*\n)/$1fn test_hio_civil_dates() = let a = hio_civil(0) in let b = hio_civil(19723) in let c = hio_civil(11016) in a.y == 1970 and a.m == 1 and a.d == 1 and b.y == 2024 and b.m == 1 and b.d == 1 and c.y == 2000 and c.m == 2 and c.d == 29\nfn test_hio_strftime() = hio_strf("%Y-%m-%dT%H:%M:%SZ", 0, 1704067261, "") == "2024-01-01T00:01:01Z" and hio_strf("%a %b %e", 0, 0, "") == "Thu Jan  1" and hio_strf("100%%", 0, 0, "") == "100%"\nfn test_hio_uname_sysname() = let s = os_uname_field(0) in s == "Linux" or s == "Windows_NT"\n/ or die "d";
open my $o, '>:raw', $f or die; print $o $t; close $o; print "date/uname added\n";

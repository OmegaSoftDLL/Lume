# Rewrite os_run*("/bin/<prog>", args, ...) for prog in mkdir rm cp mv chmod into the Lume module hostio:
#   os_run("/bin/P", A)                          -> hio_run("P", A)
#   os_run_capture("/bin/P", A, O, E)            -> hio_run_capture("P", A, O, E)
#   os_run_capture_timeout("/bin/P", A, O, E, T) -> hio_run_capture("P", A, O, E)
# Arguments are copied verbatim (balanced parentheses and string literals are respected), so every argument
# expression is evaluated exactly as before. `use hostio` is added once to a file that gains a call.
# Usage: perl rewrite_coreutils.pl file...   (prints one line per file with the number of rewrites)
use strict; use warnings;

sub split_args {    # text between the call's parentheses -> list of top-level argument strings
  my ($s) = @_;
  my @out; my $depth = 0; my $cur = ''; my $i = 0; my $n = length $s;
  while ($i < $n) {
    my $c = substr($s, $i, 1);
    if ($c eq '"') {
      my $j = $i + 1;
      while ($j < $n) { my $d = substr($s, $j, 1); if ($d eq '\\') { $j += 2; next } last if $d eq '"'; $j++ }
      $cur .= substr($s, $i, $j - $i + 1); $i = $j + 1; next;
    }
    if ($c eq '(') { $depth++ } elsif ($c eq ')') { $depth-- }
    if ($c eq ',' && $depth == 0) { push @out, $cur; $cur = ''; $i++; next }
    $cur .= $c; $i++;
  }
  push @out, $cur if $cur ne '' || @out;
  s/^\s+|\s+$//g for @out;
  return @out;
}

sub close_paren {   # index of the ')' matching the '(' at $open
  my ($t, $open) = @_;
  my $depth = 0; my $i = $open; my $n = length $t;
  while ($i < $n) {
    my $c = substr($t, $i, 1);
    if ($c eq '"') { my $j = $i + 1; while ($j < $n) { my $d = substr($t, $j, 1); if ($d eq '\\') { $j += 2; next } last if $d eq '"'; $j++ } $i = $j + 1; next }
    if ($c eq '(') { $depth++ } elsif ($c eq ')') { $depth--; return $i if $depth == 0 }
    $i++;
  }
  return -1;
}

for my $f (@ARGV) {
  open my $in, '<:raw', $f or die "$f: $!"; local $/; my $t = <$in>; close $in;
  my $count = 0; my $pos = 0; my $res = '';
  while ($t =~ /\b(os_run(?:_capture(?:_timeout)?)?)\(\s*"\/bin\/(mkdir|rm|cp|mv|chmod)"\s*,/g) {
    my ($fn, $prog) = ($1, $2);
    my $start = $-[0];
    my $open = index($t, '(', $start);
    my $close = close_paren($t, $open);
    die "$f: unbalanced call at $start\n" if $close < 0;
    my @a = split_args(substr($t, $open + 1, $close - $open - 1));
    my $rep;
    if ($fn eq 'os_run') { die "$f: os_run arity\n" unless @a == 2; $rep = "hio_run(\"$prog\", $a[1])" }
    elsif ($fn eq 'os_run_capture') { die "$f: capture arity\n" unless @a == 4; $rep = "hio_run_capture(\"$prog\", $a[1], $a[2], $a[3])" }
    else { die "$f: timeout arity\n" unless @a == 5; $rep = "hio_run_capture(\"$prog\", $a[1], $a[2], $a[3])" }
    $res .= substr($t, $pos, $start - $pos) . $rep;
    $pos = $close + 1;
    pos($t) = $pos;
    $count++;
  }
  next unless $count;
  $res .= substr($t, $pos);
  if ($res !~ /^use hostio$/m) {
    # after the existing `use` lines, else after the leading comment block
    if ($res =~ /\A((?:.*\n)*?(?:use [^\n]*\n))(?!use )/ && $res =~ /^use /m) {
      my @lines = split /\n/, $res, -1; my $last = -1;
      for my $k (0 .. $#lines) { $last = $k if $lines[$k] =~ /^use / }
      splice @lines, $last + 1, 0, 'use hostio';
      $res = join "\n", @lines;
    } else {
      my @lines = split /\n/, $res, -1; my $k = 0;
      $k++ while $k < @lines && $lines[$k] =~ /^#/;
      splice @lines, $k, 0, 'use hostio';
      $res = join "\n", @lines;
    }
  }
  open my $o, '>:raw', $f or die; print $o $res; close $o;
  print "$f: $count\n";
}

# Third driver patch: on a Windows host, "-o app.exe" is the native console program (the full language),
# not the fixed GUI template; the GUI template stays available with --target x86_64-windows-gui.
use strict; use warnings;
local $/;
my $f = shift;
open my $in, '<:raw', $f or die "$f: $!";
my $t = <$in>;
close $in;
my $old = 'fn ld_infer_target(out) = if ld_suffix(out, ".exe") or ld_suffix(out, ".EXE") then "x86_64-windows-gui" else';
my $new = "## \"x86_64-linux-elf\" is the driver's name for the host-native build path (lumec + lasm with ld_host_cflags /\n## ld_host_aflags): on a Windows host it produces a Windows console program, so .exe selects it there\nfn ld_infer_target(out) = if (ld_suffix(out, \".exe\") or ld_suffix(out, \".EXE\")) and os_platform() == \"windows\" then \"x86_64-linux-elf\" else if ld_suffix(out, \".exe\") or ld_suffix(out, \".EXE\") then \"x86_64-windows-gui\" else";
my $i = index($t, $old);
die "pattern not found\n" if $i < 0;
substr($t, $i, length($old)) = $new;
open my $o, '>:raw', $f or die;
print $o $t;
close $o;
print "driver patched: ld_infer_target\n";

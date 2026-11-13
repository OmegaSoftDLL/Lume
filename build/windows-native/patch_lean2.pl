use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
my $old = "    jmp .Lwst_argv_ready\n.Lwst_argv_commit:\n";
my $new = "# the three parts every start touches (pointers, strings, raw command line): committed now, 64 KiB each, so an\n# ordinary start takes no fault; anything larger commits on first touch\n" .
  join('', map { "    leaq $_(%rbx), %rcx\n    movq \$65536, %rdx\n    movq \$4096, %r8\n    movq \$4, %r9\n    call VirtualAlloc\n" } (0, 1048576, 3145728)) .
  "    jmp .Lwst_argv_ready\n.Lwst_argv_commit:\n";
my $i = index($t, $old); die "nf" if $i < 0; substr($t, $i, length($old)) = $new;
$t =~ s/    leaq 0\(%rbx\), %rcx\n/    movq %rbx, %rcx\n/ or die "z";
open my $o, '>:raw', $f or die; print $o $t; close $o; print "ok\n";

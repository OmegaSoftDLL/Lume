local $/; my $f = shift; open my $i, '<:raw', $f; my $t = <$i>; close $i;
my $old = "## solver is started through /bin/sh with an 8 MiB stack limit: this process raises its own stack limit and a child\n## inherits it, and z3 then cannot map its thread stacks under an address-space limit (`ulimit -v`) and dies with\n## std::system_error before it prints anything. An EMPTY";
my $new = "## solver is started directly: the runtime gives every child the stack limit this process started with (it raises\n## its own to 4 GiB, and z3 cannot map its thread stacks under an address-space limit (`ulimit -v`) when it inherits\n## that; it dies with std::system_error before it prints anything). An EMPTY";
my $k = index($t, $old); die "nf" if $k < 0; substr($t, $k, length($old)) = $new;
open my $o, '>:raw', $f; print $o $t; close $o; print "ok\n";

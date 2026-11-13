use strict; use warnings; use JSON::PP;
my ($jsonl, $outdir) = @ARGV;
my %want = ('domains_122_map.md' => qr/## Invent\x{e1}rio dos 122/, 'processor_memory_audit.md' => qr/## Auditoria: processadores internos/);
my %got;
open my $f, '<:raw', $jsonl or die;
sub walk { my ($v) = @_; if (ref $v eq 'HASH') { walk($_) for values %$v } elsif (ref $v eq 'ARRAY') { walk($_) for @$v } elsif (defined $v && !ref $v) { for my $k (keys %want) { if ($v =~ $want{$k}) { my $i = index($v, '## '); my $t = substr($v, $i); $t =~ s/^  //mg; $got{$k} = $t if !$got{$k} || length($t) > length($got{$k}); } } } }
while (my $l = <$f>) { next unless $l =~ /Invent|Auditoria: processadores/; my $d = eval { JSON::PP->new->utf8->decode($l) } or next; walk($d); }
for my $k (keys %got) { open my $o, '>:utf8', "$outdir/$k" or die; print $o $got{$k}; close $o; print "$k ", length($got{$k}), "\n"; }

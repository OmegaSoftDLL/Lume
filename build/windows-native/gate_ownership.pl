local $/; my $f = shift; open my $i, '<:raw', $f; my $t = <$i>; close $i; my $n = 0;
$n += ($t =~ s/root \+ "\/build\/bin\//hio_bin_dir(root) + "\//g);
sub rep { my ($o, $nw) = @_; my $k = index($t, $o); die "nf: $o" if $k < 0; substr($t, $k, length($o)) = $nw; $n++ }
rep('fn og_lumec(root, name, src, tmp) = let out = tmp + "/" + name + ".s" in let st = og_input(hio_bin_dir(root) + "/lumec", og_dir(root) + "/" + name + ".src", out) in',
    'fn og_lumec(root, name, src, tmp) = let out = tmp + "/" + name + ".s" in let st = hio_osrun_ict(hio_bin_dir(root) + "/lumec", hio_cflags(), og_dir(root) + "/" + name + ".src", out, out + ".err", 120000) in');
rep('og_run(hio_bin_dir(root) + "/lasm", Cons("--strict", Cons(c.asm, Nil)), elf)', 'og_run(hio_bin_dir(root) + "/lasm", hio_aflags(c.asm), elf)');
open my $o, '>:raw', $f; print $o $t; close $o; print "$f: $n\n";

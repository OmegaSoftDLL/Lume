local $/; for my $f (@ARGV) { open my $i, '<:raw', $f; my $t = <$i>; close $i;
my $n = ($t =~ s/fs_path_exists\((hio_bin_dir\([a-z.]+\) \+ "\/[a-z_0-9]+")\)/fs_path_exists(hio_exe_path($1))/g) || 0;
open my $o, '>:raw', $f; print $o $t; close $o; print "$f: $n\n"; }

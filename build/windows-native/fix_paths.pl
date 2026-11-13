# Replace host paths fixed in string literals by the portable helpers of hostio (adds `use hostio`).
use strict; use warnings;
for my $f (@ARGV) {
  open my $in, '<:raw', $f or die; local $/; my $t = <$in>; close $in; my $o = $t;
  # whole functions with user-specific paths
  $t =~ s/^fn mem_root_dir\(\) = .*$/fn mem_root_dir() = let d = hio_data_dir() in if hio_mkdir_p(d) == 1 then d else let z = fs_mkdir("\/tmp\/.lume_sovereign_memory") in "\/tmp\/.lume_sovereign_memory"/m;
  $t =~ s/^fn mem_vault_active\(\) = .*$/fn mem_vault_active() = if fs_path_exists(hio_lume_home()) == 1 then hio_lume_home() + "\/lume_memory.jsonl" else "\/tmp\/lume_memory.jsonl"/m;
  $t =~ s/^fn mem_vault_win_dir\(\) = .*$/fn mem_vault_win_dir() = let w = hio_win_home() + "\/.lume" in if fs_path_exists(w) == 1 then w + "\/sovereign_memory" else "\/tmp\/.lume_win_vault"/m;
  # literals
  $t =~ s{/mnt/c/Users/Ricardo\.Bueno/Downloads}{" + hio_win_home() + "/Downloads}g;
  $t =~ s{/root/\.lume_sovereign_memory}{" + hio_data_dir() + "}g;
  $t =~ s{/var/lib/lume_sovereign_vault}{" + hio_system_vault() + "}g;
  $t =~ s{/mnt/c/Windows/System32}{" + hio_win_system32() + "}g;
  $t =~ s{/root/\.lume/}{" + hio_lume_home() + "/}g;
  $t =~ s{"/root/\.lume"}{hio_lume_home()}g;
  $t =~ s{"/root/\.lume\\"}{"" + hio_lume_home() + "\\"}g;
  # tidy the empty pieces the substitution leaves
  $t =~ s/"" \+ (hio_[a-z0-9_]+\(\))/$1/g;
  $t =~ s/(hio_[a-z0-9_]+\(\)) \+ ""/$1/g;
  next if $t eq $o;
  if ($t !~ /^use hostio$/m) { my @l = split /\n/, $t, -1; my $last = -1; for my $k (0 .. $#l) { $last = $k if $l[$k] =~ /^use / } if ($last < 0) { $last = 0; $last++ while $last < @l && $l[$last] =~ /^#/; $last-- } splice @l, $last + 1, 0, 'use hostio'; $t = join "\n", @l }
  open my $w, '>:raw', $f or die; print $w $t; close $w; print "$f fixed\n";
}

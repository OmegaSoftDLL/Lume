local $/;
sub edit { my ($f, $code) = @_; open my $i, '<:raw', $f; local $_ = <$i>; close $i; my $n = $code->(); if ($_ !~ /^use hostio$/m) { my @l = split /\n/, $_, -1; my $k = 0; $k++ while $k < @l && $l[$k] =~ /^#/; splice @l, $k, 0, 'use hostio'; $_ = join "\n", @l } open my $o, '>:raw', $f; print $o $_; close $o; print "$f: $n\n" }
edit('prover_fuzz.src', sub { my $n = 0;
  $n += s/let c = pf_input\(cfg\.lumec, Nil, sp, cfg\.tmp \+ "\/" \+ tag \+ "\.s"\)/let c = pf_input(cfg.lumec, hio_cflags(), sp, cfg.tmp + "\/" + tag + ".s")/;
  $n += s/pf_run\(cfg\.lasm, Cons\("--strict", Cons\(cfg\.tmp \+ "\/" \+ tag \+ "\.s", Nil\)\), cfg\.tmp \+ "\/" \+ tag \+ "\.elf"\)/pf_run(cfg.lasm, hio_aflags(cfg.tmp + "\/" + tag + ".s"), cfg.tmp + "\/" + tag + hio_exe_ext())/;
  $n += s/\+ tag \+ "\.elf"/+ tag + hio_exe_ext()/g;
  $n += s/root \+ "\/build\/bin\//hio_bin_dir(root) + "\//g;
  $n });
edit('runtime_sync_gate.src', sub { my $n = 0;
  $n += s/let st = rs_input\(root \+ "\/build\/bin\/lumec", src, s\) in if st != 0 then "lumec rejected " \+ name/let st = hio_osrun_ict(hio_bin_dir(root) + "\/lumec", hio_cflags(), src, s, s + ".err", 120000) in if st != 0 then "lumec rejected " + name/;
  $n += s/rs_run\(root \+ "\/build\/bin\/lasm", Cons\("--strict", Cons\(s, Nil\)\), elf\)/rs_run(hio_bin_dir(root) + "\/lasm", hio_aflags(s), elf)/;
  $n += s/root \+ "\/build\/bin\//hio_bin_dir(root) + "\//g;
  $n });

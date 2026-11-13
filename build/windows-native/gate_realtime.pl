local $/; my $f = shift; open my $i, '<:raw', $f; my $t = <$i>; close $i; my $n = 0;
sub rep { my ($o, $nw) = @_; my $k = index($t, $o); die "nf: $o" if $k < 0; substr($t, $k, length($o)) = $nw; $n++ }
rep('fn rg_lumec(cfg, name, args, src) = let sp = cfg.tmp + "/" + name + ".src" in let w = fs_write_sync(sp, src) in rg_input(cfg.root + "/build/bin/lumec", args, sp, cfg.tmp + "/" + name + ".s")',
    "## on Windows the same program is also compiled with --win64 (<name>.w.s), the form rg_link assembles and runs;\n## <name>.s stays the Linux assembly every analysis of this gate reads, so both hosts check the same text\n" .
    'fn rg_lumec(cfg, name, args, src) = let sp = cfg.tmp + "/" + name + ".src" in let w = fs_write_sync(sp, src) in let r = rg_input(hio_bin_dir(cfg.root) + "/lumec", args, sp, cfg.tmp + "/" + name + ".s") in let h = if os_platform() == "windows" and r.status == 0 then rg_input(hio_bin_dir(cfg.root) + "/lumec", Cons("--win64", args), sp, cfg.tmp + "/" + name + ".w.s") else r in r');
rep('let a = rg_run(cfg.root + "/build/bin/lasm", Cons("--strict", Cons(cfg.tmp + "/" + name + ".s", Nil)), cfg.tmp + "/" + name + ".elf")',
    'let a = rg_run(hio_bin_dir(cfg.root) + "/lasm", hio_aflags(cfg.tmp + "/" + name + (if os_platform() == "windows" then ".w.s" else ".s")), cfg.tmp + "/" + name + hio_exe_ext())');
$n += ($t =~ s/cfg\.root \+ "\/build\/bin\//hio_bin_dir(cfg.root) + "\//g);
$n += ($t =~ s/\+ "(\/[a-z_0-9]+)\.elf"/+ "$1" + hio_exe_ext()/g);
$n += ($t =~ s/\+ name \+ "\.elf"/+ name + hio_exe_ext()/g);
if ($t !~ /^use hostio$/m) { $t = "use hostio\n" . $t }
open my $o, '>:raw', $f; print $o $t; close $o; print "$f: $n\n";

# ltv --exec (native boundary run) and lmcdc (witness driver): build and run the program for this host
use strict; use warnings; local $/;
sub edit { my ($f, $code) = @_; open my $i, '<:raw', $f or die; local $_ = <$i>; close $i; my $n = $code->(); open my $o, '>:raw', $f; print $o $_; close $o; print "$f: $n\n" }
edit('ltv.src', sub { my $n = 0;
  $n += s/os_run_input_capture_timeout\(root \+ "\/build\/bin\/lumec", Nil, work \+ "\.exec\.src"/os_run_input_capture_timeout(hio_bin_dir(root) + "\/lumec", hio_cflags(), work + ".exec.src"/;
  $n += s/hio_osrun_ct\(root \+ "\/build\/bin\/lasm", Cons\("--strict", Cons\(work \+ "\.exec\.s", Nil\)\), work \+ "\.exec\.elf"/hio_osrun_ct(hio_bin_dir(root) + "\/lasm", hio_aflags(work + ".exec.s"), work + ".exec" + hio_exe_ext()/;
  $n += s/Cons\(work \+ "\.exec\.elf", Nil\)\)\) in let x = hio_osrun_ct\(work \+ "\.exec\.elf"/Cons(work + ".exec" + hio_exe_ext(), Nil))) in let x = hio_osrun_ct(work + ".exec" + hio_exe_ext()/;
  $n });
edit('lmcdc.src', sub { my $n = 0;
  $n += s/os_run_input_capture_timeout\(root \+ "\/build\/bin\/lumec", Nil, tmp \+ "\/mcdc\.src"/os_run_input_capture_timeout(hio_bin_dir(root) + "\/lumec", hio_cflags(), tmp + "\/mcdc.src"/;
  $n += s/os_run_capture_timeout\(root \+ "\/build\/bin\/lasm", Cons\("--strict", Cons\(tmp \+ "\/mcdc\.s", Nil\)\), tmp \+ "\/mcdc\.elf"/os_run_capture_timeout(hio_bin_dir(root) + "\/lasm", hio_aflags(tmp + "\/mcdc.s"), tmp + "\/mcdc" + hio_exe_ext()/;
  $n += s/Cons\(tmp \+ "\/mcdc\.elf", Nil\)\)\) in let r = mc_run_all\(tmp \+ "\/mcdc\.elf"/Cons(tmp + "\/mcdc" + hio_exe_ext(), Nil))) in let r = mc_run_all(tmp + "\/mcdc" + hio_exe_ext()/;
  $n });

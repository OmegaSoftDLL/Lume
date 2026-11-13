use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in;
my $s = index($t, 'let prot_cmd = '); die "s" if $s < 0;
my $e = index($t, 'let prot_rc = ', $s); die "e" if $e < 0;
substr($t, $s, $e - $s) = '';
my $old = 'hio_osrun_ct("/bin/sh", Cons("-c", Cons(prot_cmd, Nil)), "/dev/null", "/dev/null", 60000)';
my $i = index($t, $old); die "old" if $i < 0;
substr($t, $i, length($old)) = 'rev_protect_build(rdir, proj_dir, dldir, wdir)';
my $fns = <<'LUME';
## protected rebuild of the reconstructed program, then the copies the report lists; stops at the first failure
## (what `lume build ... && cp ... && cp ...` did through /bin/sh, without a shell)
fn rev_cp(srcs, dst) = hio_run("cp", Cons("-f", hio_cat(srcs, Cons(dst, Nil))))
fn rev_protect_build(rdir, proj, dl, wdir) = let b = hio_osrun_ct(hio_lume_bin(), Cons("build", Cons(rdir + "/lume_reversa_reconstructed.src", Cons("-o", Cons(rdir + "/lume_reversa_reconstructed_protected", Cons("--protect", Cons("max", Cons("--lsym", Cons(rdir + "/lume_reversa_reconstructed.lsym", Nil)))))))), "/dev/null", "/dev/null", 60000) in if b != 0 then b else rev_protect_copies(rdir, proj, dl, wdir)
fn rev_protect_copies(rdir, proj, dl, wdir) = let pa = proj + "/LumePad_PlusPlus_Protected_AntiREA.exe" in let ls = rdir + "/lume_reversa_reconstructed.lsym" in let pr = rdir + "/lume_reversa_reconstructed_protected" in let c1 = rev_cp(Cons(pa, Nil), dl + "/LumePad_PlusPlus.exe") in if c1 != 0 then c1 else let c2 = rev_cp(Cons(pa, Nil), dl + "/lume_reversa_reconstructed_protected.exe") in if c2 != 0 then c2 else let c3 = rev_cp(Cons(proj + "/LumePad_PlusPlus_Unprotected.exe", Nil), dl + "/lume_reversa_reconstructed_unprotected.exe") in if c3 != 0 then c3 else let c4 = rev_cp(Cons(pa, Nil), pr + ".exe") in if c4 != 0 then c4 else let c5 = rev_cp(Cons(ls, Nil), proj + "/LumePad_PlusPlus.lsym") in if c5 != 0 then c5 else let c6 = rev_cp(Cons(ls, Cons(pr, Cons(pr + ".exe", Nil))), wdir + "/") in if c6 != 0 then c6 else rev_cp(Cons(ls, Cons(pr, Nil)), dl + "/")
LUME
my $anchor = 'fn sentience_reverse_engineer_json(';
my $j = index($t, $anchor); die "anchor" if $j < 0;
substr($t, $j, 0) = $fns;
open my $o, '>:raw', $f or die; print $o $t; close $o; print "prot shell replaced\n";

# lasm: `call *%reg` / `jmp *%reg` (FF /2, FF /4), the register-indirect forms; no symbol, no relocation.
use strict; use warnings; local $/;
my $f = shift; open my $in, '<:raw', $f or die; my $t = <$in>; close $in; my $n = 0;
sub rep { my ($o, $nw) = @_; my $i = index($t, $o); die "nf: $o" if $i < 0; substr($t, $i, length($o)) = $nw; $n++ }
rep('fn encjmp(mn, ins, iend, syms) = if ins.nop != 1 then badops(ins) else Cons(',
    "## `call *%reg` / `jmp *%reg`: a register operand, encoded FF /2 (call) or FF /4 (jmp), REX.B for r8-r15\n" .
    'fn isind(t) = count(t) > 2 and at(t, 0) == "*" and at(t, 1) == "%"' . "\n" .
    'fn encind(mn, ins) = let r = regnum(slice(ins.tgt, 1, count(ins.tgt))) in if r < 0 or r > 15 then badops(ins) else app(if r >= 8 then Cons(65, Nil) else Nil, Cons(255, Cons((if mn == "call" then 208 else 224) + r % 8, Nil)))' . "\n" .
    'fn encjmp(mn, ins, iend, syms) = if ins.nop != 1 then badops(ins) else if isind(ins.tgt) then encind(mn, ins) else Cons(');
rep('fn needsreloc(r) = if isjump(r.mn) then 1 else', 'fn needsreloc(r) = if isjump(r.mn) and not isind(r.tgt) then 1 else if isjump(r.mn) then 0 else');
rep('fn chkinsref(r, syms) = if isjump(r.mn) then chksym(', 'fn chkinsref(r, syms) = if isjump(r.mn) and isind(r.tgt) then 0 else if isjump(r.mn) then chksym(');
rep('fn chkinsref0(r, syms) = if isjump(r.mn) then chkname(', 'fn chkinsref0(r, syms) = if isjump(r.mn) and isind(r.tgt) then 0 else if isjump(r.mn) then chkname(');
open my $o, '>:raw', $f or die; print $o $t; close $o; print "lasm indirect: $n\n";

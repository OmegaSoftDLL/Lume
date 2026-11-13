# Repair the rt_fs_files patch whose "\n" escapes were written as real newlines.
# The damaged region starts at "fs_copy: and ends at the last "jmp mkint" piece of fs_make_executable.
local $/;
my $f = shift;
open my $in, '<:raw', $f or die "$f: $!";
my $t = <$in>;
close $in;
my $start = index($t, '"fs_copy:');
die "start not found" if $start < 0;
my $mark = '.Lrt_fmx_ret:';
my $m = index($t, $mark, $start);
die "end mark not found" if $m < 0;
my $end = index($t, "jmp mkint", $m);
die "end not found" if $end < 0;
$end += length("jmp mkint");
# the damaged piece terminator is: newline + '"'
die "unexpected terminator" unless substr($t, $end, 2) eq "\n\"";
$end += 2;
my $region = substr($t, $start, $end - $start);
my $n = ($region =~ s/\n"/\\n"/g);
substr($t, $start, $end - $start) = $region;
open my $out, '>:raw', $f or die;
print $out $t;
close $out;
print "repaired $n pieces\n";

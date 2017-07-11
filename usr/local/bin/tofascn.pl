#!/usr/bin/perl
#
# tofascn.pl v1.5
# vim: ts=2 nowrap
#
#
# Usage: ./tofascn.pl <FASC-N in 200-bit format> 
#
# Converts 200-bit format FASC-N to human-readble form
# 
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/../lib/perl/lib';
use LogParser qw(&cook);

# Check args

if (@ARGV < 1) {
	die "Usage: $0 <raw FASC-N>\n";
}

my $length = length $ARGV[0];
die "Invalid input length ($length)\n" if (length $ARGV[0] != 50);

my $fascn = cook($ARGV[0]);

$length = length $fascn;
die "Invalid output length ($fascn)\n" if (length $fascn != 32);

print "$fascn\n";

exit 0;

package LogParser;
# LogParser.pm v1.5

use strict;
use warnings;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(cook clean output_value tlvparse);
%EXPORT_TAGS = ( DEFAULT => [qw(&cook)],
                 All     => [qw(&cook &clean &output_value &tlvparse)]);

#
# Deconstructs a 200-bit raw FASC-N to cooked form.
#

sub cook($) {
	my $raw = shift;
	my @hexdigits = ();
	my $value;
	my @bits = ();
	my $bctr;
	my $bitstr = "";
	my $digits = "";
	my $length;

	@hexdigits = unpack "(A)*", $raw; 

	# Convert each hex digit to 4 0's and 1's and concatenate to into a string.

	map { $bitstr .= sprintf("%04b", hex($_)); } @hexdigits;

	# Create a bit array so we can read 5 bits at a time.

	@bits = split //, $bitstr;

	for ($length = scalar @bits, $value = 0, $bctr = 0; $bctr < $length - 5; $bctr++) {

		# The bits of each digit are reversed, with a trailing parity bit

		$value |= ((($bits[$bctr] == 1) ? 0x01 : 0x00) << ($bctr % 5));

		# Peek if we've done 5 bits, process, and roll over to another digit

		if (($bctr + 1) % 5 == 0) { 
			# Strip off high order (parity bit)
			$value = $value & 0xF; 
			# All of the field separators, etc., are > 9 so
			$digits .= $value if ($value < 10);
			# Ready for next digit
			$value = 0;
		}
	}

	return $digits
}

#
# Cleans a line of ASCII hex of spaces or colons
#

sub clean($) {
	my $line = shift;
	$line =~ s/:|\s//g;
	return $line;
}

#
# Prints out the value and writes it to the specified file 
#

sub output_value($$$$$$$) {
	my $start = shift;
	my $len = shift;
	my $name = shift;
	my $charsref = shift;
	my $octets = shift;
	my $hashableref = shift;
	my $base64cons = shift;
	my $end = $start + $len;
	my $outfile;
	my $encoded;
	my @chars = @$charsref;
	my $hashable = $hashableref;

	return if ($len == 0);

	open $outfile, ">$name" . ".bin" or die "$outfile" . ".bin" . ": $!";
	my $i;
	for ($i = $start; $i < $end; $i++) {
		if (defined $hashableref && defined $$hashable) {
			$$hashable .= chr($chars[$i]);
		}
		print $outfile chr($chars[$i]);
	}

	close $outfile;	

	# So that we can pipe this directly in to openssl asn1parse -inform pem ...

	if ($base64cons == 1) {
		$encoded = MIME::Base64::encode (substr ($octets, $start, $len));
		print $encoded, "\n";
	}
}

#
# Parses a TLV, returning the tag, length, and value
#

sub tlvparse ($) {
	my $charsref = shift;
	my @chars = @$charsref;
	my $len = 0;
	my $tag = $chars[0];
	my $lenbytes;
	shift @chars;
	if ($chars[0] & 0x80) {
		$lenbytes = $chars[0] & 0x7F;
		for (my $j = 0, $len = 0; $j < $lenbytes; $j++) {
			shift @chars;
			$len = (($len << 8) | $chars[0]);
		}
	} else {
		$len = $chars[0];
	}
	shift @chars;
	return ($tag, $len, @chars);
}

1;

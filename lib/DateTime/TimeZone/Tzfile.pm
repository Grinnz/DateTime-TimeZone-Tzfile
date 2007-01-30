package DateTime::TimeZone::Tzfile;

use warnings;
use strict;

use Carp qw(croak);
use IO::File;

sub _saferead($$) {
	my($fh, $len) = @_;
	my $data;
	my $rlen = $fh->read($data, $len);
	croak "can't read tzfile: $!" unless defined($rlen);
	croak "can't parse tzfile: premature EOF" unless $rlen == $len;
	return $data;
}

sub _read_u32($) { unpack("N", _saferead($_[0], 4)) }

sub _read_s32($) {
	my $uval = _read_u32($_[0]);
	return ($uval & 0x80000000) ? ($uval & 0x7fffffff) - 0x80000000 :
				      $uval;
}

sub _read_u8($) { ord(_saferead($_[0], 1)) }

sub new($$) {
	my($class, $filename) = @_;
	croak "filename must be absolute" unless $filename =~ m#\A/#;
	my $fh = IO::File->new($filename, "r")
		or croak "can't read $filename: $!";
	croak "can't parse tzfile: bad magic"
		unless _saferead($fh, 4) eq "TZif";
	my $fmtversion = _saferead($fh, 1);
	_saferead($fh, 15);
	my($ttisgmtcnt, $ttisstdcnt, $leapcnt, $timecnt, $typecnt, $charcnt) =
		map { _read_u32($fh) } 1 .. 6;
	my @obs_times = map { _read_s32($fh) } 1 .. $timecnt;
	my @obs_types = map { _read_u8($fh) } 1 .. $timecnt;
	my @types = map {
		{
			gmtoff => _read_s32($fh),
			isdst => _read_u8($fh),
			abbrind => _read_u8($fh),
		}
	} 1 .. $typecnt;
	my $chars = _saferead($fh, $charcnt);
	for(my $i = $leapcnt; $i--; ) { _saferead($fh, 8); }
	for(my $i = $ttisstdcnt; $i--; ) { _saferead($fh, 1); }
	for(my $i = $ttisgmtcnt; $i--; ) { _saferead($fh, 1); }
	if($fmtversion eq "2") {
		# TODO: read 64-bit version of same data
	}
	$fh = undef;
	die "TODO";
}

1;

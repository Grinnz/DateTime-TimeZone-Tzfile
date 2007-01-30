package DateTime::TimeZone::Tzfile;

use warnings;
use strict;

use Carp qw(croak);
use IO::File;

sub fdiv($$) {
	# TODO: do this properly
	use POSIX qw(floor);
	return floor($_[0] / $_[1]);
}

sub fmod($$) {
	# TODO: do this properly
	return $_[0] - $_[1] * fdiv($_[0], $_[1]);
}

sub _saferead($$) {
	my($fh, $len) = @_;
	my $data;
	my $rlen = $fh->read($data, $len);
	croak "can't read tzfile: $!" unless defined($rlen);
	croak "bad tzfile: premature EOF" unless $rlen == $len;
	return $data;
}

sub _read_u32($) { unpack("N", _saferead($_[0], 4)) }

sub _read_s32($) {
	my $uval = _read_u32($_[0]);
	return ($uval & 0x80000000) ? ($uval & 0x7fffffff) - 0x80000000 :
				      $uval;
}

sub _read_u8($) { ord(_saferead($_[0], 1)) }

use constant UNIX_EPOCH_RDN => 719163;

sub _read_tm32($) {
	my $t = _read_s32($_[0]);
	return [ UNIX_EPOCH_RDN + fdiv($t, 86400), fmod($t, 86400) ];
}

sub _read_tm64($) {
	# TODO: make this neater
	my($fh) = @_;
	my $th = _read_s32($fh);
	my $tl = _read_u32($fh);
	my $dh = fdiv($th, 86400);
	$th = (fmod($th, 86400) << 10) | ($tl >> 22);
	my $d2 = fdiv($th, 86400);
	$th = (fmod($th, 86400) << 10) | (($tl >> 12) & 0x3ff);
	my $d3 = fdiv($th, 86400);
	$th = (fmod($th, 86400) << 12) | ($tl & 0xfff);
	my $d4 = fdiv($th, 86400);
	$th = fmod($th, 86400);
	my $d = $dh * 4294967296 + $d2 * 4194304 + (($d3 << 12) + $d4);
	return [ UNIX_EPOCH_RDN + $d, $th ];
}

sub new($$) {
	my($class, $filename) = @_;
	#croak "filename must be absolute" unless $filename =~ m#\A/#;
	my $fh = IO::File->new($filename, "r")
		or croak "can't read $filename: $!";
	croak "bad tzfile: wrong magic number"
		unless _saferead($fh, 4) eq "TZif";
	my $fmtversion = _saferead($fh, 1);
	_saferead($fh, 15);
	my($ttisgmtcnt, $ttisstdcnt, $leapcnt, $timecnt, $typecnt, $charcnt) =
		map { _read_u32($fh) } 1 .. 6;
	croak "bad tzfile: no local time types" if $typecnt == 0;
	my @trn_times = map { _read_tm32($fh) } 1 .. $timecnt;
	my @obs_types = map { _read_u8($fh) } 1 .. $timecnt;
	my @types = map {
		[ _read_s32($fh), !!_read_u8($fh), _read_u8($fh) ]
	} 1 .. $typecnt;
	my $chars = _saferead($fh, $charcnt);
	for(my $i = $leapcnt; $i--; ) { _saferead($fh, 8); }
	for(my $i = $ttisstdcnt; $i--; ) { _saferead($fh, 1); }
	for(my $i = $ttisgmtcnt; $i--; ) { _saferead($fh, 1); }
	my $late_rule = "";
	if($fmtversion eq "2") {
		croak "bad tzfile: wrong magic number"
			unless _saferead($fh, 4) eq "TZif";
		_saferead($fh, 16);
		($ttisgmtcnt, $ttisstdcnt, $leapcnt,
		 $timecnt, $typecnt, $charcnt) =
			map { _read_u32($fh) } 1 .. 6;
		croak "bad tzfile: no local time types" if $typecnt == 0;
		@trn_times = map { _read_tm64($fh) } 1 .. $timecnt;
		@obs_types = map { _read_u8($fh) } 1 .. $timecnt;
		@types = map {
			[ _read_s32($fh), !!_read_u8($fh), _read_u8($fh) ]
		} 1 .. $typecnt;
		$chars = _saferead($fh, $charcnt);
		for(my $i = $leapcnt; $i--; ) { _saferead($fh, 12); }
		for(my $i = $ttisstdcnt; $i--; ) { _saferead($fh, 1); }
		for(my $i = $ttisgmtcnt; $i--; ) { _saferead($fh, 1); }
		croak "bad tzfile: missing newline"
			unless _saferead($fh, 1) eq "\x0a";
		while(1) {
			my $c = _saferead($fh, 1);
			last if $c eq "\x0a";
			$late_rule .= $c;
		}
	}
	$fh = undef;
	for(my $i = @trn_times - 1; $i-- > 0; ) {
		unless(($trn_times[$i]->[0] <=> $trn_times[$i+1]->[0] ||
			$trn_times[$i]->[1] <=> $trn_times[$i+1]->[1]) == -1) {
			croak "bad tzfile: unsorted change times";
		}
	}
	foreach (@obs_types) {
		croak "bad tzfile: invalid local time type index"
			if $_ >= $typecnt;
		$_ = $types[$_];
	}
	my $first_std_type;
	foreach my $type (@types) {
		my $abbrind = $type->[2];
		croak "bad tzfile: invalid abbreviation index"
			if $abbrind > $charcnt;
		pos($chars) = $abbrind;
		$chars =~ /\G([^\0]*)/g;
		$type->[2] = $1;
		$first_std_type = $type
			if !defined($first_std_type) && !$type->[1];
	}
	unshift @obs_types,
		defined($first_std_type) ? $first_std_type : $types[0];
	return bless({
		trn_times => \@trn_times,
		obs_types => \@obs_types,
		late_rule => $late_rule,
	}, $class);
}

sub _dump_obs($) {
	my($obs) = @_;
	return sprintf("%+5d,%s,%s", $obs->[0], $obs->[1] ? "dst" : "std",
				     $obs->[2]);
}

sub dump($) {
	use Date::ISO8601 qw(present_ymd);
	use Date::JD qw(rdn_to_cjdn);
	my($self) = @_;
	printf "initial: %s\n", _dump_obs($self->{obs_types}->[0]);
	for(my $i = 0; $i != @{$self->{trn_times}}; $i++) {
		my($trn_rdn, $trn_secs) = @{$self->{trn_times}->[$i]};
		printf "from %sT%02d:%02d:%02dZ: %s\n",
			present_ymd(rdn_to_cjdn($trn_rdn)),
			fdiv($trn_secs, 3600),
			fdiv($trn_secs, 60) % 60,
			$trn_secs % 60,
			_dump_obs($self->{obs_types}->[$i+1]);
	}
	printf "later: %s\n", $self->{late_rule};
}

1;

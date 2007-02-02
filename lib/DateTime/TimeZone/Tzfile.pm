package DateTime::TimeZone::Tzfile;

use warnings;
use strict;

use Carp qw(croak);
use IO::File 1.03;

# fdiv(A, B), fmod(A, B): divide A by B, flooring remainder
#
# B must be a positive Perl integer.  A must be a Perl integer.

sub fdiv($$) {
	my($a, $b) = @_;
	if($a < 0) {
		use integer;
		return -(($b - 1 - $a) / $b);
	} else {
		use integer;
		return $a / $b;
	}
}

sub fmod($$) { $_[0] % $_[1] }

#
# file reading
#

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

#
# construct object, reading tzfile
#

sub new($$) {
	my($class, $filename) = @_;
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
	my $first_std_type_index;
	my %offsets;
	my $has_dst;
	for(my $i = 0; $i != $typecnt; $i++) {
		my $abbrind = $types[$i]->[2];
		croak "bad tzfile: invalid abbreviation index"
			if $abbrind > $charcnt;
		pos($chars) = $abbrind;
		$chars =~ /\G([^\0]*)/g;
		$types[$i]->[2] = $1;
		$first_std_type_index = $i
			if !defined($first_std_type_index) && !$types[$i]->[1];
		$has_dst = 1 if $types[$i]->[1];
		if($types[$i]->[2] eq "zzz") {
			# "zzz" means the zone is not defined at this time,
			# due for example to the location being uninhabited
			$types[$i] = undef;
		} else {
			$offsets{$types[$i]->[0]} = undef;
		}
	}
	unshift @obs_types,
		defined($first_std_type_index) ? $first_std_type_index : 0;
	foreach my $obs_type (@obs_types) {
		croak "bad tzfile: invalid local time type index"
			if $obs_type >= $typecnt;
		$obs_type = $types[$obs_type];
	}
	$obs_types[-1] = $late_rule eq "" ? undef : eval {
		require DateTime::TimeZone::SystemV;
		DateTime::TimeZone::SystemV->new($late_rule);
	};
	return bless({
		name => $filename,
		has_dst => $has_dst,
		trn_times => \@trn_times,
		obs_types => \@obs_types,
		offsets => [ sort { $a <=> $b } keys %offsets ],
	}, $class);
}

#
# identity methods
#

sub is_floating($) { 0 }
sub is_utc($) { 0 }
sub is_olson($) { 0 }
sub category($) { undef }
sub name($) { $_[0]->{name} }

#
# offset methods
#

sub has_dst_changes($) { $_[0]->{has_dst} }

sub _type_for_rdn_sod($$$) {
	my($self, $utc_rdn, $utc_sod) = @_;
	my $lo = 0;
	my $hi = @{$self->{trn_times}};
	while($lo != $hi) {
		my $try = do { use integer; ($lo + $hi) / 2 };
		if(($utc_rdn <=> $self->{trn_times}->[$try]->[0] ||
		    $utc_sod <=> $self->{trn_times}->[$try]->[1]) == -1) {
			$hi = $try;
		} else {
			$lo = $try + 1;
		}
	}
	my $type = $self->{obs_types}->[$lo];
	croak "local time not defined for this time" unless defined $type;
	return $type;
}

sub _type_for_datetime($$) {
	my($self, $dt) = @_;
	my($utc_rdn, $utc_sod) = $dt->utc_rd_values;
	$utc_sod = 86399 if $utc_sod >= 86400;
	return $self->_type_for_rdn_sod($utc_rdn, $utc_sod);
}

sub is_dst_for_datetime($$) {
	my($self, $dt) = @_;
	my $type = $self->_type_for_datetime($dt);
	return ref($type) eq "ARRAY" ? $type->[1] :
		$type->is_dst_for_datetime($dt);
}

sub offset_for_datetime($$) {
	my($self, $dt) = @_;
	my $type = $self->_type_for_datetime($dt);
	return ref($type) eq "ARRAY" ? $type->[0] :
		$type->offset_for_datetime($dt);
}

sub short_name_for_datetime($$) {
	my($self, $dt) = @_;
	my $type = $self->_type_for_datetime($dt);
	return ref($type) eq "ARRAY" ? $type->[2] :
		$type->short_name_for_datetime($dt);
}

sub _local_to_utc_rdn_sod($$$) {
	my($rdn, $sod, $offset) = @_;
	$sod -= $offset;
	while($sod < 0) {
		$rdn--;
		$sod += 86400;
	}
	while($sod >= 86400) {
		$rdn++;
		$sod -= 86400;
	}
	return ($rdn, $sod);
}

sub offset_for_local_datetime($$) {
	my($self, $dt) = @_;
	my($lcl_rdn, $lcl_sod) = $dt->local_rd_values;
	$lcl_sod = 86399 if $lcl_sod >= 86400;
	foreach my $offset (@{$self->{offsets}}) {
		my($utc_rdn, $utc_sod) =
			_local_to_utc_rdn_sod($lcl_rdn, $lcl_sod, $offset);
		my $ttype =
			eval { $self->_type_for_rdn_sod($utc_rdn, $utc_sod) };
		return $ttype->[0]
			if defined($ttype) && $ttype->[0] == $offset;
	}
	croak "non-existent local time due to offset change";
}

1;

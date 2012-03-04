use warnings;
use strict;

use Test::More tests => 43;

{
	package FakeLocalDateTime;
	use Date::ISO8601 0.000 qw(ymd_to_cjdn);
	use Date::JD 0.005 qw(cjdn_to_rdnn);
	sub new {
		my($class, $y, $mo, $d, $h, $mi, $s) = @_;
		return bless({
			rdn => cjdn_to_rdnn(ymd_to_cjdn($y, $mo, $d)),
			sod => 3600*$h + 60*$mi + $s,
		}, $class);
	}
	sub local_rd_values { ($_[0]->{rdn}, $_[0]->{sod}, 0) }
}

require_ok "DateTime::TimeZone::Tzfile";

my $tz;

sub try($$) {
	my($timespec, $offset) = @_;
	$timespec =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})T
			([0-9]{2}):([0-9]{2}):([0-9]{2})\z/x or die;
	my $dt = FakeLocalDateTime->new("$1", "$2", "$3", "$4", "$5", "$6");
	my $errcond;
	unless($offset =~ /\A[-+]?[0-9]+\z/) {
		$errcond = $offset;
		$offset = undef;
	}
	is eval { $tz->offset_for_local_datetime($dt) }, $offset,
		"offset for $timespec";
	unless(defined $offset) {
		like $@, qr#\A
			local\ time\ \Q$timespec\E\ does\ not\ exist
			\ in\ the\ [!-~]+\ timezone\ due\ to\ \Q$errcond\E
		\b#x, "error message for $timespec";
	}
}

$tz = DateTime::TimeZone::Tzfile->new("t/london.tz");
try "1800-01-01T00:00:00", -75;
try "1920-03-28T01:59:59", +0;
try "1920-03-28T02:00:00", "offset change";
try "1920-03-28T02:59:59", "offset change";
try "1920-03-28T03:00:00", +3600;
try "1920-10-25T01:59:59", +3600;
try "1920-10-25T02:00:00", +0;
try "1920-10-25T02:59:59", +0;
try "1920-10-25T03:00:00", +0;
try "1942-04-05T01:59:59", +3600;
try "1942-04-05T02:00:00", "offset change";
try "1942-04-05T02:59:59", "offset change";
try "1942-04-05T03:00:00", +7200;
try "2039-03-27T00:59:59", +0;
try "2039-03-27T01:00:00", "offset change";
try "2039-03-27T01:59:59", "offset change";
try "2039-03-27T02:00:00", +3600;
try "2039-10-30T00:59:59", +3600;
try "2039-10-30T01:00:00", +0;
try "2039-10-30T01:59:59", +0;
try "2039-10-30T02:00:00", +0;

$tz = DateTime::TimeZone::Tzfile->new("t/davis.tz");
try "1953-07-01T12:00:00", "zone disuse";
try "1957-01-13T06:59:59", "zone disuse";
try "1957-01-13T07:00:00", +25200;
try "1960-01-01T12:00:00", +25200;
try "1964-10-31T23:59:59", +25200;
try "1964-11-01T00:00:00", "zone disuse";
try "1967-01-01T12:00:00", "zone disuse";
try "1969-02-01T06:59:59", "zone disuse";
try "1969-02-01T07:00:00", +25200;
try "1980-01-01T12:00:00", +25200;

1;

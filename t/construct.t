use Test::More tests => 14;

require_ok "DateTime::TimeZone::Tzfile";

$tz = DateTime::TimeZone::Tzfile->new("t/london.tz");
ok $tz;
is $tz->name, "t/london.tz";

$tz = DateTime::TimeZone::Tzfile->new(filename => "t/london.tz");
ok $tz;
is $tz->name, "t/london.tz";

$tz = DateTime::TimeZone::Tzfile->new(filename => "t/london.tz",
	name => "foobar");
ok $tz;
is $tz->name, "foobar";

$tz = DateTime::TimeZone::Tzfile->new(name => "foobar",
	filename => "t/london.tz");
ok $tz;
is $tz->name, "foobar";

eval { DateTime::TimeZone::Tzfile->new(); };
like $@, qr/\Afilename not specified\b/;

eval { DateTime::TimeZone::Tzfile->new(name => "foobar"); };
like $@, qr/\Afilename not specified\b/;

eval { DateTime::TimeZone::Tzfile->new(quux => "foobar"); };
like $@, qr/\Aunrecognised attribute\b/;

eval { DateTime::TimeZone::Tzfile->new(name => "foobar", name => "quux"); };
like $@, qr/\Atimezone name specified redundantly\b/;

eval {
	DateTime::TimeZone::Tzfile->new(filename => "t/london.tz",
		filename => "t/london.tz");
};
like $@, qr/\Afilename specified redundantly\b/;

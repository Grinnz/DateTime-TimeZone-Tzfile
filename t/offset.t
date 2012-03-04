use warnings;
use strict;

use Test::More tests => 1516;

{
	package FakeUtcDateTime;
	use Date::ISO8601 0.000 qw(ymd_to_cjdn);
	use Date::JD 0.005 qw(cjdn_to_rdnn);
	sub new {
		my($class, $y, $mo, $d, $h, $mi, $s) = @_;
		return bless({
			rdn => cjdn_to_rdnn(ymd_to_cjdn($y, $mo, $d)),
			sod => 3600*$h + 60*$mi + $s,
		}, $class);
	}
	sub utc_rd_values { ($_[0]->{rdn}, $_[0]->{sod}, 0) }
}

require_ok "DateTime::TimeZone::Tzfile";

my $tz;

sub try($$;$$) {
	my($timespec, $is_dst, $offset, $abbrev) = @_;
	$timespec =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})T
			([0-9]{2}):([0-9]{2}):([0-9]{2})Z\z/x or die;
	my $dt = FakeUtcDateTime->new("$1", "$2", "$3", "$4", "$5", "$6");
	my $errcond;
	unless($is_dst =~ /\A[01]\z/) {
		$errcond = $is_dst;
		$is_dst = undef;
	}
	if(defined $is_dst) {
		is !!$tz->is_dst_for_datetime($dt), !!$is_dst,
			"is DST for $timespec";
		is $tz->offset_for_datetime($dt), $offset,
			"offset for $timespec";
		is $tz->short_name_for_datetime($dt), $abbrev,
			"abbrev for $timespec";
	} else {
		foreach my $method (qw(
			is_dst_for_datetime
			offset_for_datetime
			short_name_for_datetime
		)) {
			eval { $tz->$method($dt) };
			like $@, qr#\A
				time\ \Q$timespec\E\ is\ not\ represented
				\ in\ the\ [!-~]+\ timezone
				\ due\ to\ \Q$errcond\E
			\b#x, "$method error message for $timespec";
		}
	}
}

$tz = DateTime::TimeZone::Tzfile->new("t/london.tz");
try "1800-01-01T00:00:00Z", 0,    -75, "LMT";
try "1847-12-01T00:01:14Z", 0,    -75, "LMT";
try "1847-12-01T00:01:15Z", 0,     +0, "GMT";
try "1916-05-21T01:59:59Z", 0,     +0, "GMT";
try "1916-05-21T02:00:00Z", 1,  +3600, "BST";
try "1916-10-01T01:59:59Z", 1,  +3600, "BST";
try "1916-10-01T02:00:00Z", 0,     +0, "GMT";
try "1917-04-08T01:59:59Z", 0,     +0, "GMT";
try "1917-04-08T02:00:00Z", 1,  +3600, "BST";
try "1917-09-17T01:59:59Z", 1,  +3600, "BST";
try "1917-09-17T02:00:00Z", 0,     +0, "GMT";
try "1918-03-24T01:59:59Z", 0,     +0, "GMT";
try "1918-03-24T02:00:00Z", 1,  +3600, "BST";
try "1918-09-30T01:59:59Z", 1,  +3600, "BST";
try "1918-09-30T02:00:00Z", 0,     +0, "GMT";
try "1919-03-30T01:59:59Z", 0,     +0, "GMT";
try "1919-03-30T02:00:00Z", 1,  +3600, "BST";
try "1919-09-29T01:59:59Z", 1,  +3600, "BST";
try "1919-09-29T02:00:00Z", 0,     +0, "GMT";
try "1920-03-28T01:59:59Z", 0,     +0, "GMT";
try "1920-03-28T02:00:00Z", 1,  +3600, "BST";
try "1920-10-25T01:59:59Z", 1,  +3600, "BST";
try "1920-10-25T02:00:00Z", 0,     +0, "GMT";
try "1921-04-03T01:59:59Z", 0,     +0, "GMT";
try "1921-04-03T02:00:00Z", 1,  +3600, "BST";
try "1921-10-03T01:59:59Z", 1,  +3600, "BST";
try "1921-10-03T02:00:00Z", 0,     +0, "GMT";
try "1922-03-26T01:59:59Z", 0,     +0, "GMT";
try "1922-03-26T02:00:00Z", 1,  +3600, "BST";
try "1922-10-08T01:59:59Z", 1,  +3600, "BST";
try "1922-10-08T02:00:00Z", 0,     +0, "GMT";
try "1923-04-22T01:59:59Z", 0,     +0, "GMT";
try "1923-04-22T02:00:00Z", 1,  +3600, "BST";
try "1923-09-16T01:59:59Z", 1,  +3600, "BST";
try "1923-09-16T02:00:00Z", 0,     +0, "GMT";
try "1924-04-13T01:59:59Z", 0,     +0, "GMT";
try "1924-04-13T02:00:00Z", 1,  +3600, "BST";
try "1924-09-21T01:59:59Z", 1,  +3600, "BST";
try "1924-09-21T02:00:00Z", 0,     +0, "GMT";
try "1925-04-19T01:59:59Z", 0,     +0, "GMT";
try "1925-04-19T02:00:00Z", 1,  +3600, "BST";
try "1925-10-04T01:59:59Z", 1,  +3600, "BST";
try "1925-10-04T02:00:00Z", 0,     +0, "GMT";
try "1926-04-18T01:59:59Z", 0,     +0, "GMT";
try "1926-04-18T02:00:00Z", 1,  +3600, "BST";
try "1926-10-03T01:59:59Z", 1,  +3600, "BST";
try "1926-10-03T02:00:00Z", 0,     +0, "GMT";
try "1927-04-10T01:59:59Z", 0,     +0, "GMT";
try "1927-04-10T02:00:00Z", 1,  +3600, "BST";
try "1927-10-02T01:59:59Z", 1,  +3600, "BST";
try "1927-10-02T02:00:00Z", 0,     +0, "GMT";
try "1928-04-22T01:59:59Z", 0,     +0, "GMT";
try "1928-04-22T02:00:00Z", 1,  +3600, "BST";
try "1928-10-07T01:59:59Z", 1,  +3600, "BST";
try "1928-10-07T02:00:00Z", 0,     +0, "GMT";
try "1929-04-21T01:59:59Z", 0,     +0, "GMT";
try "1929-04-21T02:00:00Z", 1,  +3600, "BST";
try "1929-10-06T01:59:59Z", 1,  +3600, "BST";
try "1929-10-06T02:00:00Z", 0,     +0, "GMT";
try "1930-04-13T01:59:59Z", 0,     +0, "GMT";
try "1930-04-13T02:00:00Z", 1,  +3600, "BST";
try "1930-10-05T01:59:59Z", 1,  +3600, "BST";
try "1930-10-05T02:00:00Z", 0,     +0, "GMT";
try "1931-04-19T01:59:59Z", 0,     +0, "GMT";
try "1931-04-19T02:00:00Z", 1,  +3600, "BST";
try "1931-10-04T01:59:59Z", 1,  +3600, "BST";
try "1931-10-04T02:00:00Z", 0,     +0, "GMT";
try "1932-04-17T01:59:59Z", 0,     +0, "GMT";
try "1932-04-17T02:00:00Z", 1,  +3600, "BST";
try "1932-10-02T01:59:59Z", 1,  +3600, "BST";
try "1932-10-02T02:00:00Z", 0,     +0, "GMT";
try "1933-04-09T01:59:59Z", 0,     +0, "GMT";
try "1933-04-09T02:00:00Z", 1,  +3600, "BST";
try "1933-10-08T01:59:59Z", 1,  +3600, "BST";
try "1933-10-08T02:00:00Z", 0,     +0, "GMT";
try "1934-04-22T01:59:59Z", 0,     +0, "GMT";
try "1934-04-22T02:00:00Z", 1,  +3600, "BST";
try "1934-10-07T01:59:59Z", 1,  +3600, "BST";
try "1934-10-07T02:00:00Z", 0,     +0, "GMT";
try "1935-04-14T01:59:59Z", 0,     +0, "GMT";
try "1935-04-14T02:00:00Z", 1,  +3600, "BST";
try "1935-10-06T01:59:59Z", 1,  +3600, "BST";
try "1935-10-06T02:00:00Z", 0,     +0, "GMT";
try "1936-04-19T01:59:59Z", 0,     +0, "GMT";
try "1936-04-19T02:00:00Z", 1,  +3600, "BST";
try "1936-10-04T01:59:59Z", 1,  +3600, "BST";
try "1936-10-04T02:00:00Z", 0,     +0, "GMT";
try "1937-04-18T01:59:59Z", 0,     +0, "GMT";
try "1937-04-18T02:00:00Z", 1,  +3600, "BST";
try "1937-10-03T01:59:59Z", 1,  +3600, "BST";
try "1937-10-03T02:00:00Z", 0,     +0, "GMT";
try "1938-04-10T01:59:59Z", 0,     +0, "GMT";
try "1938-04-10T02:00:00Z", 1,  +3600, "BST";
try "1938-10-02T01:59:59Z", 1,  +3600, "BST";
try "1938-10-02T02:00:00Z", 0,     +0, "GMT";
try "1939-04-16T01:59:59Z", 0,     +0, "GMT";
try "1939-04-16T02:00:00Z", 1,  +3600, "BST";
try "1939-11-19T01:59:59Z", 1,  +3600, "BST";
try "1939-11-19T02:00:00Z", 0,     +0, "GMT";
try "1940-02-25T01:59:59Z", 0,     +0, "GMT";
try "1940-02-25T02:00:00Z", 1,  +3600, "BST";
try "1941-05-04T00:59:59Z", 1,  +3600, "BST";
try "1941-05-04T01:00:00Z", 1,  +7200, "BDST";
try "1941-08-10T00:59:59Z", 1,  +7200, "BDST";
try "1941-08-10T01:00:00Z", 1,  +3600, "BST";
try "1942-04-05T00:59:59Z", 1,  +3600, "BST";
try "1942-04-05T01:00:00Z", 1,  +7200, "BDST";
try "1942-08-09T00:59:59Z", 1,  +7200, "BDST";
try "1942-08-09T01:00:00Z", 1,  +3600, "BST";
try "1943-04-04T00:59:59Z", 1,  +3600, "BST";
try "1943-04-04T01:00:00Z", 1,  +7200, "BDST";
try "1943-08-15T00:59:59Z", 1,  +7200, "BDST";
try "1943-08-15T01:00:00Z", 1,  +3600, "BST";
try "1944-04-02T00:59:59Z", 1,  +3600, "BST";
try "1944-04-02T01:00:00Z", 1,  +7200, "BDST";
try "1944-09-17T00:59:59Z", 1,  +7200, "BDST";
try "1944-09-17T01:00:00Z", 1,  +3600, "BST";
try "1945-04-02T00:59:59Z", 1,  +3600, "BST";
try "1945-04-02T01:00:00Z", 1,  +7200, "BDST";
try "1945-07-15T00:59:59Z", 1,  +7200, "BDST";
try "1945-07-15T01:00:00Z", 1,  +3600, "BST";
try "1945-10-07T01:59:59Z", 1,  +3600, "BST";
try "1945-10-07T02:00:00Z", 0,     +0, "GMT";
try "1946-04-14T01:59:59Z", 0,     +0, "GMT";
try "1946-04-14T02:00:00Z", 1,  +3600, "BST";
try "1946-10-06T01:59:59Z", 1,  +3600, "BST";
try "1946-10-06T02:00:00Z", 0,     +0, "GMT";
try "1947-03-16T01:59:59Z", 0,     +0, "GMT";
try "1947-03-16T02:00:00Z", 1,  +3600, "BST";
try "1947-04-13T00:59:59Z", 1,  +3600, "BST";
try "1947-04-13T01:00:00Z", 1,  +7200, "BDST";
try "1947-08-10T00:59:59Z", 1,  +7200, "BDST";
try "1947-08-10T01:00:00Z", 1,  +3600, "BST";
try "1947-11-02T01:59:59Z", 1,  +3600, "BST";
try "1947-11-02T02:00:00Z", 0,     +0, "GMT";
try "1948-03-14T01:59:59Z", 0,     +0, "GMT";
try "1948-03-14T02:00:00Z", 1,  +3600, "BST";
try "1948-10-31T01:59:59Z", 1,  +3600, "BST";
try "1948-10-31T02:00:00Z", 0,     +0, "GMT";
try "1949-04-03T01:59:59Z", 0,     +0, "GMT";
try "1949-04-03T02:00:00Z", 1,  +3600, "BST";
try "1949-10-30T01:59:59Z", 1,  +3600, "BST";
try "1949-10-30T02:00:00Z", 0,     +0, "GMT";
try "1950-04-16T01:59:59Z", 0,     +0, "GMT";
try "1950-04-16T02:00:00Z", 1,  +3600, "BST";
try "1950-10-22T01:59:59Z", 1,  +3600, "BST";
try "1950-10-22T02:00:00Z", 0,     +0, "GMT";
try "1951-04-15T01:59:59Z", 0,     +0, "GMT";
try "1951-04-15T02:00:00Z", 1,  +3600, "BST";
try "1951-10-21T01:59:59Z", 1,  +3600, "BST";
try "1951-10-21T02:00:00Z", 0,     +0, "GMT";
try "1952-04-20T01:59:59Z", 0,     +0, "GMT";
try "1952-04-20T02:00:00Z", 1,  +3600, "BST";
try "1952-10-26T01:59:59Z", 1,  +3600, "BST";
try "1952-10-26T02:00:00Z", 0,     +0, "GMT";
try "1953-04-19T01:59:59Z", 0,     +0, "GMT";
try "1953-04-19T02:00:00Z", 1,  +3600, "BST";
try "1953-10-04T01:59:59Z", 1,  +3600, "BST";
try "1953-10-04T02:00:00Z", 0,     +0, "GMT";
try "1954-04-11T01:59:59Z", 0,     +0, "GMT";
try "1954-04-11T02:00:00Z", 1,  +3600, "BST";
try "1954-10-03T01:59:59Z", 1,  +3600, "BST";
try "1954-10-03T02:00:00Z", 0,     +0, "GMT";
try "1955-04-17T01:59:59Z", 0,     +0, "GMT";
try "1955-04-17T02:00:00Z", 1,  +3600, "BST";
try "1955-10-02T01:59:59Z", 1,  +3600, "BST";
try "1955-10-02T02:00:00Z", 0,     +0, "GMT";
try "1956-04-22T01:59:59Z", 0,     +0, "GMT";
try "1956-04-22T02:00:00Z", 1,  +3600, "BST";
try "1956-10-07T01:59:59Z", 1,  +3600, "BST";
try "1956-10-07T02:00:00Z", 0,     +0, "GMT";
try "1957-04-14T01:59:59Z", 0,     +0, "GMT";
try "1957-04-14T02:00:00Z", 1,  +3600, "BST";
try "1957-10-06T01:59:59Z", 1,  +3600, "BST";
try "1957-10-06T02:00:00Z", 0,     +0, "GMT";
try "1958-04-20T01:59:59Z", 0,     +0, "GMT";
try "1958-04-20T02:00:00Z", 1,  +3600, "BST";
try "1958-10-05T01:59:59Z", 1,  +3600, "BST";
try "1958-10-05T02:00:00Z", 0,     +0, "GMT";
try "1959-04-19T01:59:59Z", 0,     +0, "GMT";
try "1959-04-19T02:00:00Z", 1,  +3600, "BST";
try "1959-10-04T01:59:59Z", 1,  +3600, "BST";
try "1959-10-04T02:00:00Z", 0,     +0, "GMT";
try "1960-04-10T01:59:59Z", 0,     +0, "GMT";
try "1960-04-10T02:00:00Z", 1,  +3600, "BST";
try "1960-10-02T01:59:59Z", 1,  +3600, "BST";
try "1960-10-02T02:00:00Z", 0,     +0, "GMT";
try "1961-03-26T01:59:59Z", 0,     +0, "GMT";
try "1961-03-26T02:00:00Z", 1,  +3600, "BST";
try "1961-10-29T01:59:59Z", 1,  +3600, "BST";
try "1961-10-29T02:00:00Z", 0,     +0, "GMT";
try "1962-03-25T01:59:59Z", 0,     +0, "GMT";
try "1962-03-25T02:00:00Z", 1,  +3600, "BST";
try "1962-10-28T01:59:59Z", 1,  +3600, "BST";
try "1962-10-28T02:00:00Z", 0,     +0, "GMT";
try "1963-03-31T01:59:59Z", 0,     +0, "GMT";
try "1963-03-31T02:00:00Z", 1,  +3600, "BST";
try "1963-10-27T01:59:59Z", 1,  +3600, "BST";
try "1963-10-27T02:00:00Z", 0,     +0, "GMT";
try "1964-03-22T01:59:59Z", 0,     +0, "GMT";
try "1964-03-22T02:00:00Z", 1,  +3600, "BST";
try "1964-10-25T01:59:59Z", 1,  +3600, "BST";
try "1964-10-25T02:00:00Z", 0,     +0, "GMT";
try "1965-03-21T01:59:59Z", 0,     +0, "GMT";
try "1965-03-21T02:00:00Z", 1,  +3600, "BST";
try "1965-10-24T01:59:59Z", 1,  +3600, "BST";
try "1965-10-24T02:00:00Z", 0,     +0, "GMT";
try "1966-03-20T01:59:59Z", 0,     +0, "GMT";
try "1966-03-20T02:00:00Z", 1,  +3600, "BST";
try "1966-10-23T01:59:59Z", 1,  +3600, "BST";
try "1966-10-23T02:00:00Z", 0,     +0, "GMT";
try "1967-03-19T01:59:59Z", 0,     +0, "GMT";
try "1967-03-19T02:00:00Z", 1,  +3600, "BST";
try "1967-10-29T01:59:59Z", 1,  +3600, "BST";
try "1967-10-29T02:00:00Z", 0,     +0, "GMT";
try "1968-02-18T01:59:59Z", 0,     +0, "GMT";
try "1968-02-18T02:00:00Z", 1,  +3600, "BST";
try "1968-10-26T22:59:59Z", 1,  +3600, "BST";
try "1968-10-26T23:00:00Z", 0,  +3600, "BST";
try "1971-10-31T01:59:59Z", 0,  +3600, "BST";
try "1971-10-31T02:00:00Z", 0,     +0, "GMT";
try "1972-03-19T01:59:59Z", 0,     +0, "GMT";
try "1972-03-19T02:00:00Z", 1,  +3600, "BST";
try "1972-10-29T01:59:59Z", 1,  +3600, "BST";
try "1972-10-29T02:00:00Z", 0,     +0, "GMT";
try "1973-03-18T01:59:59Z", 0,     +0, "GMT";
try "1973-03-18T02:00:00Z", 1,  +3600, "BST";
try "1973-10-28T01:59:59Z", 1,  +3600, "BST";
try "1973-10-28T02:00:00Z", 0,     +0, "GMT";
try "1974-03-17T01:59:59Z", 0,     +0, "GMT";
try "1974-03-17T02:00:00Z", 1,  +3600, "BST";
try "1974-10-27T01:59:59Z", 1,  +3600, "BST";
try "1974-10-27T02:00:00Z", 0,     +0, "GMT";
try "1975-03-16T01:59:59Z", 0,     +0, "GMT";
try "1975-03-16T02:00:00Z", 1,  +3600, "BST";
try "1975-10-26T01:59:59Z", 1,  +3600, "BST";
try "1975-10-26T02:00:00Z", 0,     +0, "GMT";
try "1976-03-21T01:59:59Z", 0,     +0, "GMT";
try "1976-03-21T02:00:00Z", 1,  +3600, "BST";
try "1976-10-24T01:59:59Z", 1,  +3600, "BST";
try "1976-10-24T02:00:00Z", 0,     +0, "GMT";
try "1977-03-20T01:59:59Z", 0,     +0, "GMT";
try "1977-03-20T02:00:00Z", 1,  +3600, "BST";
try "1977-10-23T01:59:59Z", 1,  +3600, "BST";
try "1977-10-23T02:00:00Z", 0,     +0, "GMT";
try "1978-03-19T01:59:59Z", 0,     +0, "GMT";
try "1978-03-19T02:00:00Z", 1,  +3600, "BST";
try "1978-10-29T01:59:59Z", 1,  +3600, "BST";
try "1978-10-29T02:00:00Z", 0,     +0, "GMT";
try "1979-03-18T01:59:59Z", 0,     +0, "GMT";
try "1979-03-18T02:00:00Z", 1,  +3600, "BST";
try "1979-10-28T01:59:59Z", 1,  +3600, "BST";
try "1979-10-28T02:00:00Z", 0,     +0, "GMT";
try "1980-03-16T01:59:59Z", 0,     +0, "GMT";
try "1980-03-16T02:00:00Z", 1,  +3600, "BST";
try "1980-10-26T01:59:59Z", 1,  +3600, "BST";
try "1980-10-26T02:00:00Z", 0,     +0, "GMT";
try "1981-03-29T00:59:59Z", 0,     +0, "GMT";
try "1981-03-29T01:00:00Z", 1,  +3600, "BST";
try "1981-10-25T00:59:59Z", 1,  +3600, "BST";
try "1981-10-25T01:00:00Z", 0,     +0, "GMT";
try "1982-03-28T00:59:59Z", 0,     +0, "GMT";
try "1982-03-28T01:00:00Z", 1,  +3600, "BST";
try "1982-10-24T00:59:59Z", 1,  +3600, "BST";
try "1982-10-24T01:00:00Z", 0,     +0, "GMT";
try "1983-03-27T00:59:59Z", 0,     +0, "GMT";
try "1983-03-27T01:00:00Z", 1,  +3600, "BST";
try "1983-10-23T00:59:59Z", 1,  +3600, "BST";
try "1983-10-23T01:00:00Z", 0,     +0, "GMT";
try "1984-03-25T00:59:59Z", 0,     +0, "GMT";
try "1984-03-25T01:00:00Z", 1,  +3600, "BST";
try "1984-10-28T00:59:59Z", 1,  +3600, "BST";
try "1984-10-28T01:00:00Z", 0,     +0, "GMT";
try "1985-03-31T00:59:59Z", 0,     +0, "GMT";
try "1985-03-31T01:00:00Z", 1,  +3600, "BST";
try "1985-10-27T00:59:59Z", 1,  +3600, "BST";
try "1985-10-27T01:00:00Z", 0,     +0, "GMT";
try "1986-03-30T00:59:59Z", 0,     +0, "GMT";
try "1986-03-30T01:00:00Z", 1,  +3600, "BST";
try "1986-10-26T00:59:59Z", 1,  +3600, "BST";
try "1986-10-26T01:00:00Z", 0,     +0, "GMT";
try "1987-03-29T00:59:59Z", 0,     +0, "GMT";
try "1987-03-29T01:00:00Z", 1,  +3600, "BST";
try "1987-10-25T00:59:59Z", 1,  +3600, "BST";
try "1987-10-25T01:00:00Z", 0,     +0, "GMT";
try "1988-03-27T00:59:59Z", 0,     +0, "GMT";
try "1988-03-27T01:00:00Z", 1,  +3600, "BST";
try "1988-10-23T00:59:59Z", 1,  +3600, "BST";
try "1988-10-23T01:00:00Z", 0,     +0, "GMT";
try "1989-03-26T00:59:59Z", 0,     +0, "GMT";
try "1989-03-26T01:00:00Z", 1,  +3600, "BST";
try "1989-10-29T00:59:59Z", 1,  +3600, "BST";
try "1989-10-29T01:00:00Z", 0,     +0, "GMT";
try "1990-03-25T00:59:59Z", 0,     +0, "GMT";
try "1990-03-25T01:00:00Z", 1,  +3600, "BST";
try "1990-10-28T00:59:59Z", 1,  +3600, "BST";
try "1990-10-28T01:00:00Z", 0,     +0, "GMT";
try "1991-03-31T00:59:59Z", 0,     +0, "GMT";
try "1991-03-31T01:00:00Z", 1,  +3600, "BST";
try "1991-10-27T00:59:59Z", 1,  +3600, "BST";
try "1991-10-27T01:00:00Z", 0,     +0, "GMT";
try "1992-03-29T00:59:59Z", 0,     +0, "GMT";
try "1992-03-29T01:00:00Z", 1,  +3600, "BST";
try "1992-10-25T00:59:59Z", 1,  +3600, "BST";
try "1992-10-25T01:00:00Z", 0,     +0, "GMT";
try "1993-03-28T00:59:59Z", 0,     +0, "GMT";
try "1993-03-28T01:00:00Z", 1,  +3600, "BST";
try "1993-10-24T00:59:59Z", 1,  +3600, "BST";
try "1993-10-24T01:00:00Z", 0,     +0, "GMT";
try "1994-03-27T00:59:59Z", 0,     +0, "GMT";
try "1994-03-27T01:00:00Z", 1,  +3600, "BST";
try "1994-10-23T00:59:59Z", 1,  +3600, "BST";
try "1994-10-23T01:00:00Z", 0,     +0, "GMT";
try "1995-03-26T00:59:59Z", 0,     +0, "GMT";
try "1995-03-26T01:00:00Z", 1,  +3600, "BST";
try "1995-10-22T00:59:59Z", 1,  +3600, "BST";
try "1995-10-22T01:00:00Z", 0,     +0, "GMT";
try "1995-12-31T23:59:59Z", 0,     +0, "GMT";
try "1996-01-01T00:00:00Z", 0,     +0, "GMT";
try "1996-03-31T00:59:59Z", 0,     +0, "GMT";
try "1996-03-31T01:00:00Z", 1,  +3600, "BST";
try "1996-10-27T00:59:59Z", 1,  +3600, "BST";
try "1996-10-27T01:00:00Z", 0,     +0, "GMT";
try "1997-03-30T00:59:59Z", 0,     +0, "GMT";
try "1997-03-30T01:00:00Z", 1,  +3600, "BST";
try "1997-10-26T00:59:59Z", 1,  +3600, "BST";
try "1997-10-26T01:00:00Z", 0,     +0, "GMT";
try "1998-03-29T00:59:59Z", 0,     +0, "GMT";
try "1998-03-29T01:00:00Z", 1,  +3600, "BST";
try "1998-10-25T00:59:59Z", 1,  +3600, "BST";
try "1998-10-25T01:00:00Z", 0,     +0, "GMT";
try "1999-03-28T00:59:59Z", 0,     +0, "GMT";
try "1999-03-28T01:00:00Z", 1,  +3600, "BST";
try "1999-10-31T00:59:59Z", 1,  +3600, "BST";
try "1999-10-31T01:00:00Z", 0,     +0, "GMT";
try "2000-03-26T00:59:59Z", 0,     +0, "GMT";
try "2000-03-26T01:00:00Z", 1,  +3600, "BST";
try "2000-10-29T00:59:59Z", 1,  +3600, "BST";
try "2000-10-29T01:00:00Z", 0,     +0, "GMT";
try "2001-03-25T00:59:59Z", 0,     +0, "GMT";
try "2001-03-25T01:00:00Z", 1,  +3600, "BST";
try "2001-10-28T00:59:59Z", 1,  +3600, "BST";
try "2001-10-28T01:00:00Z", 0,     +0, "GMT";
try "2002-03-31T00:59:59Z", 0,     +0, "GMT";
try "2002-03-31T01:00:00Z", 1,  +3600, "BST";
try "2002-10-27T00:59:59Z", 1,  +3600, "BST";
try "2002-10-27T01:00:00Z", 0,     +0, "GMT";
try "2003-03-30T00:59:59Z", 0,     +0, "GMT";
try "2003-03-30T01:00:00Z", 1,  +3600, "BST";
try "2003-10-26T00:59:59Z", 1,  +3600, "BST";
try "2003-10-26T01:00:00Z", 0,     +0, "GMT";
try "2004-03-28T00:59:59Z", 0,     +0, "GMT";
try "2004-03-28T01:00:00Z", 1,  +3600, "BST";
try "2004-10-31T00:59:59Z", 1,  +3600, "BST";
try "2004-10-31T01:00:00Z", 0,     +0, "GMT";
try "2005-03-27T00:59:59Z", 0,     +0, "GMT";
try "2005-03-27T01:00:00Z", 1,  +3600, "BST";
try "2005-10-30T00:59:59Z", 1,  +3600, "BST";
try "2005-10-30T01:00:00Z", 0,     +0, "GMT";
try "2006-03-26T00:59:59Z", 0,     +0, "GMT";
try "2006-03-26T01:00:00Z", 1,  +3600, "BST";
try "2006-10-29T00:59:59Z", 1,  +3600, "BST";
try "2006-10-29T01:00:00Z", 0,     +0, "GMT";
try "2007-03-25T00:59:59Z", 0,     +0, "GMT";
try "2007-03-25T01:00:00Z", 1,  +3600, "BST";
try "2007-10-28T00:59:59Z", 1,  +3600, "BST";
try "2007-10-28T01:00:00Z", 0,     +0, "GMT";
try "2008-03-30T00:59:59Z", 0,     +0, "GMT";
try "2008-03-30T01:00:00Z", 1,  +3600, "BST";
try "2008-10-26T00:59:59Z", 1,  +3600, "BST";
try "2008-10-26T01:00:00Z", 0,     +0, "GMT";
try "2009-03-29T00:59:59Z", 0,     +0, "GMT";
try "2009-03-29T01:00:00Z", 1,  +3600, "BST";
try "2009-10-25T00:59:59Z", 1,  +3600, "BST";
try "2009-10-25T01:00:00Z", 0,     +0, "GMT";
try "2010-03-28T00:59:59Z", 0,     +0, "GMT";
try "2010-03-28T01:00:00Z", 1,  +3600, "BST";
try "2010-10-31T00:59:59Z", 1,  +3600, "BST";
try "2010-10-31T01:00:00Z", 0,     +0, "GMT";
try "2011-03-27T00:59:59Z", 0,     +0, "GMT";
try "2011-03-27T01:00:00Z", 1,  +3600, "BST";
try "2011-10-30T00:59:59Z", 1,  +3600, "BST";
try "2011-10-30T01:00:00Z", 0,     +0, "GMT";
try "2012-03-25T00:59:59Z", 0,     +0, "GMT";
try "2012-03-25T01:00:00Z", 1,  +3600, "BST";
try "2012-10-28T00:59:59Z", 1,  +3600, "BST";
try "2012-10-28T01:00:00Z", 0,     +0, "GMT";
try "2013-03-31T00:59:59Z", 0,     +0, "GMT";
try "2013-03-31T01:00:00Z", 1,  +3600, "BST";
try "2013-10-27T00:59:59Z", 1,  +3600, "BST";
try "2013-10-27T01:00:00Z", 0,     +0, "GMT";
try "2014-03-30T00:59:59Z", 0,     +0, "GMT";
try "2014-03-30T01:00:00Z", 1,  +3600, "BST";
try "2014-10-26T00:59:59Z", 1,  +3600, "BST";
try "2014-10-26T01:00:00Z", 0,     +0, "GMT";
try "2015-03-29T00:59:59Z", 0,     +0, "GMT";
try "2015-03-29T01:00:00Z", 1,  +3600, "BST";
try "2015-10-25T00:59:59Z", 1,  +3600, "BST";
try "2015-10-25T01:00:00Z", 0,     +0, "GMT";
try "2016-03-27T00:59:59Z", 0,     +0, "GMT";
try "2016-03-27T01:00:00Z", 1,  +3600, "BST";
try "2016-10-30T00:59:59Z", 1,  +3600, "BST";
try "2016-10-30T01:00:00Z", 0,     +0, "GMT";
try "2017-03-26T00:59:59Z", 0,     +0, "GMT";
try "2017-03-26T01:00:00Z", 1,  +3600, "BST";
try "2017-10-29T00:59:59Z", 1,  +3600, "BST";
try "2017-10-29T01:00:00Z", 0,     +0, "GMT";
try "2018-03-25T00:59:59Z", 0,     +0, "GMT";
try "2018-03-25T01:00:00Z", 1,  +3600, "BST";
try "2018-10-28T00:59:59Z", 1,  +3600, "BST";
try "2018-10-28T01:00:00Z", 0,     +0, "GMT";
try "2019-03-31T00:59:59Z", 0,     +0, "GMT";
try "2019-03-31T01:00:00Z", 1,  +3600, "BST";
try "2019-10-27T00:59:59Z", 1,  +3600, "BST";
try "2019-10-27T01:00:00Z", 0,     +0, "GMT";
try "2020-03-29T00:59:59Z", 0,     +0, "GMT";
try "2020-03-29T01:00:00Z", 1,  +3600, "BST";
try "2020-10-25T00:59:59Z", 1,  +3600, "BST";
try "2020-10-25T01:00:00Z", 0,     +0, "GMT";
try "2021-03-28T00:59:59Z", 0,     +0, "GMT";
try "2021-03-28T01:00:00Z", 1,  +3600, "BST";
try "2021-10-31T00:59:59Z", 1,  +3600, "BST";
try "2021-10-31T01:00:00Z", 0,     +0, "GMT";
try "2022-03-27T00:59:59Z", 0,     +0, "GMT";
try "2022-03-27T01:00:00Z", 1,  +3600, "BST";
try "2022-10-30T00:59:59Z", 1,  +3600, "BST";
try "2022-10-30T01:00:00Z", 0,     +0, "GMT";
try "2023-03-26T00:59:59Z", 0,     +0, "GMT";
try "2023-03-26T01:00:00Z", 1,  +3600, "BST";
try "2023-10-29T00:59:59Z", 1,  +3600, "BST";
try "2023-10-29T01:00:00Z", 0,     +0, "GMT";
try "2024-03-31T00:59:59Z", 0,     +0, "GMT";
try "2024-03-31T01:00:00Z", 1,  +3600, "BST";
try "2024-10-27T00:59:59Z", 1,  +3600, "BST";
try "2024-10-27T01:00:00Z", 0,     +0, "GMT";
try "2025-03-30T00:59:59Z", 0,     +0, "GMT";
try "2025-03-30T01:00:00Z", 1,  +3600, "BST";
try "2025-10-26T00:59:59Z", 1,  +3600, "BST";
try "2025-10-26T01:00:00Z", 0,     +0, "GMT";
try "2026-03-29T00:59:59Z", 0,     +0, "GMT";
try "2026-03-29T01:00:00Z", 1,  +3600, "BST";
try "2026-10-25T00:59:59Z", 1,  +3600, "BST";
try "2026-10-25T01:00:00Z", 0,     +0, "GMT";
try "2027-03-28T00:59:59Z", 0,     +0, "GMT";
try "2027-03-28T01:00:00Z", 1,  +3600, "BST";
try "2027-10-31T00:59:59Z", 1,  +3600, "BST";
try "2027-10-31T01:00:00Z", 0,     +0, "GMT";
try "2028-03-26T00:59:59Z", 0,     +0, "GMT";
try "2028-03-26T01:00:00Z", 1,  +3600, "BST";
try "2028-10-29T00:59:59Z", 1,  +3600, "BST";
try "2028-10-29T01:00:00Z", 0,     +0, "GMT";
try "2029-03-25T00:59:59Z", 0,     +0, "GMT";
try "2029-03-25T01:00:00Z", 1,  +3600, "BST";
try "2029-10-28T00:59:59Z", 1,  +3600, "BST";
try "2029-10-28T01:00:00Z", 0,     +0, "GMT";
try "2030-03-31T00:59:59Z", 0,     +0, "GMT";
try "2030-03-31T01:00:00Z", 1,  +3600, "BST";
try "2030-10-27T00:59:59Z", 1,  +3600, "BST";
try "2030-10-27T01:00:00Z", 0,     +0, "GMT";
try "2031-03-30T00:59:59Z", 0,     +0, "GMT";
try "2031-03-30T01:00:00Z", 1,  +3600, "BST";
try "2031-10-26T00:59:59Z", 1,  +3600, "BST";
try "2031-10-26T01:00:00Z", 0,     +0, "GMT";
try "2032-03-28T00:59:59Z", 0,     +0, "GMT";
try "2032-03-28T01:00:00Z", 1,  +3600, "BST";
try "2032-10-31T00:59:59Z", 1,  +3600, "BST";
try "2032-10-31T01:00:00Z", 0,     +0, "GMT";
try "2033-03-27T00:59:59Z", 0,     +0, "GMT";
try "2033-03-27T01:00:00Z", 1,  +3600, "BST";
try "2033-10-30T00:59:59Z", 1,  +3600, "BST";
try "2033-10-30T01:00:00Z", 0,     +0, "GMT";
try "2034-03-26T00:59:59Z", 0,     +0, "GMT";
try "2034-03-26T01:00:00Z", 1,  +3600, "BST";
try "2034-10-29T00:59:59Z", 1,  +3600, "BST";
try "2034-10-29T01:00:00Z", 0,     +0, "GMT";
try "2035-03-25T00:59:59Z", 0,     +0, "GMT";
try "2035-03-25T01:00:00Z", 1,  +3600, "BST";
try "2035-10-28T00:59:59Z", 1,  +3600, "BST";
try "2035-10-28T01:00:00Z", 0,     +0, "GMT";
try "2036-03-30T00:59:59Z", 0,     +0, "GMT";
try "2036-03-30T01:00:00Z", 1,  +3600, "BST";
try "2036-10-26T00:59:59Z", 1,  +3600, "BST";
try "2036-10-26T01:00:00Z", 0,     +0, "GMT";
try "2037-03-29T00:59:59Z", 0,     +0, "GMT";
try "2037-03-29T01:00:00Z", 1,  +3600, "BST";
try "2037-10-25T00:59:59Z", 1,  +3600, "BST";
try "2037-10-25T01:00:00Z", 0,     +0, "GMT";
try "2038-03-28T00:59:59Z", 0,     +0, "GMT";
try "2038-03-28T01:00:00Z", 1,  +3600, "BST";
try "2038-10-31T00:59:59Z", 1,  +3600, "BST";
try "2038-10-31T01:00:00Z", 0,     +0, "GMT";
try "2039-03-27T00:59:59Z", 0,     +0, "GMT";
try "2039-03-27T01:00:00Z", 1,  +3600, "BST";
try "2039-10-30T00:59:59Z", 1,  +3600, "BST";
try "2039-10-30T01:00:00Z", 0,     +0, "GMT";

$tz = DateTime::TimeZone::Tzfile->new("t/davis.tz");
try "1953-07-01T12:00:00Z", "zone disuse";
try "1957-01-12T23:59:59Z", "zone disuse";
try "1957-01-13T00:00:00Z", 0, +25200, "DAVT";
try "1960-01-01T12:00:00Z", 0, +25200, "DAVT";
try "1964-10-31T16:59:59Z", 0, +25200, "DAVT";
try "1964-10-31T17:00:00Z", "zone disuse";
try "1967-01-01T12:00:00Z", "zone disuse";
try "1969-01-31T23:59:59Z", "zone disuse";
try "1969-02-01T00:00:00Z", 0, +25200, "DAVT";
try "1980-01-01T12:00:00Z", 0, +25200, "DAVT";

1;

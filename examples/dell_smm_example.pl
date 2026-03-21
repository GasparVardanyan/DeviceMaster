#!/usr/bin/env perl

use strict;
use warnings;

use JSON::XS ();
use IO::Socket::UNIX ();

my $HOME = $ENV {HOME};

my $json = JSON::XS->new->utf8->canonical;
my $socket = IO::Socket::UNIX->new (
	Type => IO::Socket::UNIX::SOCK_STREAM,
	Peer => '/tmp/devicemaster.socket'
);

sub dm_get {
	my $path = shift;

	my $request = "{\"type\": \"Get\", \"path\": \"$path\"}\n";

	print $socket "$request";
	my $r = <$socket>;

	return $r;
}

my $j = $json->decode (dm_get ('/hwmons'));

my @hwmons = sort keys %{ $j->{response} };

my ($hwmon) = map {
	keys %{ $_ };
} grep {
	my ($h, $n) = %{ $_ };
	$n eq 'dell_smm'
} map {
	{ $_ => $json->decode (dm_get ("/hwmons/$_/FI/name"))->{response} };
} @hwmons;


if (defined $hwmon) {
	$hwmon = '/hwmons/' . $hwmon . '/FI/temp1_input';

	for (my $i = 0; $i < 3; $i++) {
		my $temp = $json->decode (dm_get ($hwmon))->{response};
		$temp =~ s/000$//;

		print $temp . "\n";

		sleep 1;
	}
}

close $socket;


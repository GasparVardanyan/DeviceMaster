#!/usr/bin/env perl

use strict;
use warnings;

package DeviceMaster::Apps::Rest;

use Mojolicious::Lite;
use Moose::Util;

use DeviceMaster::DeviceSystem;

my $deviceSystem = DeviceMaster::DeviceSystem->new;

get '/' => sub {
	my $c = shift;
	$c->render (text => $deviceSystem->freeze);
};

get '/get' => sub {
	my $c = shift;
	$c->render (text => $deviceSystem->freeze);
};

get '/get/*rest' => sub {
	my $c = shift;

	my $path = $c->stash ('rest');
	$path =~ s#/FI/#/feature_interfaces/#g;

	my $df = $deviceSystem->dive ($path);

	if (Moose::Util::does_role ($$df, 'DeviceMaster::FeatureInterface')) {
		$c->render (text => $$df->acquire . "\n");
	}
	elsif (Moose::Util::does_role ($$df, 'DeviceMaster::Device')) {
		$c->render (text => $$df->freeze . "\n");
	}
	else {
		$c->render (text => "err\n");
	}
};

app->start;

1;

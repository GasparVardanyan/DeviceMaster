#!/usr/bin/env perl

use strict;
use warnings;

use lib '.';

use DeviceMaster::Apps::JRPC;
use DeviceMaster::DeviceSystem;

my $jrpc = DeviceMaster::Apps::JRPC->new (
	path => '/tmp/devicemaster.socket'
);

$jrpc->listen;

#!/usr/bin/env perl

use strict;
use warnings;

use DeviceMaster::Apps::Daemon;
my $d = DeviceMaster::Apps::Daemon->new;
$d->run;

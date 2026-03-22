#!/usr/bin/env perl

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

use DeviceMaster::Apps::Daemon;
my $d = DeviceMaster::Apps::Daemon->new;
$d->run;

#!/usr/bin/env perl

use strict;
use warnings;

use lib '.';

# package DeviceMaster::Apps {
# 	use MooseX::App;
# 	use DeviceMaster::Apps::Daemon;
#
# 	__PACKAGE__->meta->make_immutable;
# }
#
# DeviceMaster::Apps->new_with_command->run;

use DeviceMaster::Apps::Daemon;
my $d = DeviceMaster::Apps::Daemon->new;
$d->run;

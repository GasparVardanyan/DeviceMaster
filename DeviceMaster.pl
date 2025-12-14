#!/usr/bin/env perl

use strict;
use warnings;

use lib '.';

package DeviceMaster::Apps {
	use MooseX::App;
	use DeviceMaster::Apps::Daemon;
}

DeviceMaster::Apps->new_with_command->run;

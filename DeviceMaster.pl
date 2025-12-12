#!/usr/bin/env perl

use strict;
use warnings;

use lib '.';

package DeviceMaster::Apps {
	use MooseX::App;
	use DeviceMaster::Apps::JRPC;
}

DeviceMaster::Apps->new_with_command->run;

#!/usr/bin/env perl

use strict;
use warnings;

package DeviceMaster::Apps::Daemon {
	use namespace::autoclean;
	use Moo;

	use DeviceMaster::AppUtils::JSONServer;
	with 'DeviceMaster::AppUtils::JSONServer';

	use Types::Standard ();

	use DeviceMaster::DeviceSystem;
	use DeviceMaster::Device;
	use DeviceMaster::FeatureInterface;

	use DeviceMaster::AppUtils::JSONProcessor;

	has json_processor => (
		is => 'ro',
		isa => Types::Standard::InstanceOf['DeviceMaster::AppUtils::JSONProcessor'],
		default => sub {
			return DeviceMaster::AppUtils::JSONProcessor->new;
		}
	);

	sub process_command {
		my $self = shift;
		my $cmd = shift;

		return $self->json_processor->process ($cmd);
	}


	__PACKAGE__->meta->make_immutable;
}

1;

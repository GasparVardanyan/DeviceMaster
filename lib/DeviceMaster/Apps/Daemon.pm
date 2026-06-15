#!/usr/bin/env perl

use strict;
use warnings;

package DeviceMaster::Apps::Daemon {
	use namespace::autoclean;
	use Moo;

	use DeviceMaster::AppUtils::JSONServer;
	with 'DeviceMaster::AppUtils::JSONServer';

	use Types::Standard ();

	use DeviceMaster::AppUtils::PathBridge;
	use DeviceMaster::AppUtils::PacketProcessor;
	use DeviceMaster::AppUtils::JSONProcessor;

	has deviceSystem => (
		is => 'ro',
		isa => Types::Standard::ScalarRef[Types::Standard::InstanceOf['DeviceMaster::DeviceSystem']],
		default => sub {
			return \DeviceMaster::DeviceSystem->new;
		},
		lazy => 1
	);

	has path_bridge => (
		is => 'ro',
		isa => Types::Standard::ScalarRef[Types::Standard::InstanceOf['DeviceMaster::AppUtils::PathBridge']],
		default => sub {
			my $self = shift;
			return \DeviceMaster::AppUtils::PathBridge->new (
				deviceSystem => $self->deviceSystem,
			);
		},
		lazy => 1
	);

	has packet_processor => (
		is => 'ro',
		isa => Types::Standard::ScalarRef[Types::Standard::InstanceOf['DeviceMaster::AppUtils::PacketProcessor']],
		default => sub {
			my $self = shift;
			return \DeviceMaster::AppUtils::PacketProcessor->new (
				deviceSystem => $self->deviceSystem,
				path_bridge => $self->path_bridge,
			);
		},
		lazy => 1
	);

	has json_processor => (
		is => 'ro',
		isa => Types::Standard::ScalarRef[Types::Standard::InstanceOf['DeviceMaster::AppUtils::JSONProcessor']],
		default => sub {
			my $self = shift;
			return \DeviceMaster::AppUtils::JSONProcessor->new (
				deviceSystem => $self->deviceSystem,
				path_bridge => $self->path_bridge,
				packet_processor => $self->packet_processor,
			);
		},
		lazy => 1
	);

	sub process_command {
		my $self = shift;
		my $cmd = shift;

		return ${$self->json_processor}->process ($cmd);
	}

	__PACKAGE__->meta->make_immutable;
}

1;

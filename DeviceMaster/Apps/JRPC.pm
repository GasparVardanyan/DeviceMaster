#!/usr/bin/env perl

use strict;
use warnings;

package DeviceMaster::Apps::JRPC::Packet {
	use namespace::autoclean;
	use Moose::Role;
	use Moose::Util;
	use Moose::Util::TypeConstraints;

	enum 'DeviceMaster::Apps::JRPC::Packet::Type' => [ 'Get', 'Set' ];

	has type => (
		is => 'ro',
		isa => 'DeviceMaster::Apps::JRPC::Packet::Type',
		required => 1
	);
};

package DeviceMaster::Apps::JRPC::Packet::Get {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::Apps::JRPC::Packet;

	with 'DeviceMaster::Apps::JRPC::Packet';

	has '+type' => (
		init_arg => undef,
		default => sub { 'Get' }
	);

	has 'path' => (
		is => 'ro',
		isa => 'Str',
		required => 1
	);
};

package DeviceMaster::Apps::JRPC::Packet::Set {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::Apps::JRPC::Packet;

	with 'DeviceMaster::Apps::JRPC::Packet';

	has '+type' => (
		init_arg => undef,
		default => sub { 'Set' }
	);

	has 'path' => (
		is => 'ro',
		isa => 'Str',
		required => 1
	);

	has 'value' => (
		is => 'ro',
		isa => 'Str',
		required => 1
	);
};

package DeviceMaster::Apps::JRPC {
	use namespace::autoclean;
	use Moose;

	use IO::Socket::UNIX;
	use threads;
	use Thread::Queue;
	use JSON::XS;

	use DeviceMaster::DeviceSystem;
	use DeviceMaster::Device;
	use DeviceMaster::FeatureInterface;

	# TODO: get rid of queues, use shared variables

	has cmd_q => (
		is => 'ro',
		isa => 'Thread::Queue',
		init_arg => undef,
		default => sub {
			Thread::Queue->new;
		}
	);

	has res_q => (
		is => 'ro',
		isa => 'Thread::Queue',
		init_arg => undef,
		default => sub {
			Thread::Queue->new;
		}
	);

	has lock_q => (
		is => 'ro',
		isa => 'ScalarRef[Int]',
		init_arg => undef,
		default => sub {
			my $s : shared = 1;
			return \$s;
		}
	);

	has path => (
		is => 'ro',
		isa => 'Str',
		required => 1
	);

	has server => (
		is => 'ro',
		isa => 'IO::Socket::UNIX',
		default => sub {
			my $self = shift;
			return IO::Socket::UNIX->new (
				Type => SOCK_STREAM,
				Local => $self->path,
				Listen => 1
			);
		},
		lazy => 1
	);

	sub _run_command {
		my $self = shift;
		my $cmd = shift;

		lock ${$self->lock_q};

		$self->cmd_q->enqueue ($cmd);
		return $self->res_q->dequeue;
	}

	sub _process_command {
		my $self = shift;
		my $dsref = shift;
		my $cmd = shift;

		my $path = $cmd->path;
		$path =~ s#/\bFI\b/#/feature_interfaces/#g;
		$path =~ s#/\bFIV\b/#/feature_interfaces_virtual/#g;

		my $df = $$dsref->dive ($path);

		if ('Get' eq $cmd->type) {
			if (Moose::Util::does_role ($$df, 'DeviceMaster::FeatureInterface')) {
				return { response => $$df->acquire, success => 1 };
			}
			elsif (
				   Moose::Util::does_role ($$df, 'DeviceMaster::Device')
				|| eval { $$df->isa ('DeviceMaster::DeviceSystem') }
			) {
				return { response => $$df->pack, success => 1 };
			}
			else {
				return { response => '', success => 0, error => 'invalid data requested' };
			}
		}
		elsif ('Set' eq $cmd->type) {
			if (Moose::Util::does_role ($$df, 'DeviceMaster::FeatureInterface')) {
				if ($$df->set ($cmd->value)) {
					return { response => $$df->acquire, success => 1 };
				}
				else {
					return { response => $$df->acquire, success => 0, error => 'failed to set the value' };
				}
			}
			else {
				return { response => '', success => 0, error => 'invalid feature requested to set a value' };
			}
		}
		else {
			return { response => '', success => 0, error => 'invalid request type' };
		}
	}

	sub _process_json {
		my $self = shift;
		my $j = shift;

		my $r;

		if (ref $j eq 'HASH') {
			$r = {
				success => 0,
				response => ''
			};

			if (exists $j->{type}) {
				my $type = $j->{type};

				if ('Get' eq $type) {
					if (exists $j->{path}) {
						my $packet = DeviceMaster::Apps::JRPC::Packet::Get->new (
							path => $j->{path}
						);

						$r = $self->_run_command ($packet);
					}
					else {
						$r->{error} = 'Get request must have a path';
					}
				}
				elsif ('Set' eq $type) {
					if (exists $j->{path} && exists $j->{value}) {
						my $packet = DeviceMaster::Apps::JRPC::Packet::Set->new (
							path => $j->{path},
							value => $j->{value}
						);

						$r = $self->_run_command ($packet);
					}
					else {
						$r->{error} = 'Set request must have path and value';
					}
				}
				else {
					$r->{error} = 'unsupported type of a command';
				}
			}
			else {
				$r->{error} = 'request must have a type';
			}

			return $r;
		}
		elsif (ref $j eq 'ARRAY') {
			$r = [
				map {
					$self->_process_json ($_)
				} @$j
			];

			return $r;
		}
		else {
			return { response => '', success => 0, error => 'invalid json signature' };
		}
	}

	sub listen {
		my $self = shift;
		while (my $conn = $self->server->accept) {
			while (my $cmd = <$conn>) {
				my $r = { response => '', success => 0, error => 'invalid json' };
				my $j = eval { JSON::XS->new->utf8->decode ($cmd) };
				if (!$@) {
					$r = $self->_process_json ($j);
				}
				$$conn->print (JSON::XS->new->utf8->canonical->encode ($r));
			}
		}
	}

	sub BUILD {
		my $self = shift;

		threads->create (sub {
			my $deviceSystem = DeviceMaster::DeviceSystem->new;
			while (my $cmd = $self->cmd_q->dequeue) {
				$self->res_q->enqueue ($self->_process_command (\$deviceSystem, $cmd));
			}
		});
	}
}

1;

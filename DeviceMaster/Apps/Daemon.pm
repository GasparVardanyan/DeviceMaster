#!/usr/bin/env perl

use strict;
use warnings;

package DeviceMaster::AppUtils::Daemon::Packet {
	use namespace::autoclean;
	use Moose::Role;
	use Moose::Util;
	use Moose::Util::TypeConstraints;

	enum 'DeviceMaster::AppUtils::Daemon::Packet::Type' => [ 'Get', 'Set' ];

	has type => (
		is => 'ro',
		isa => 'DeviceMaster::AppUtils::Daemon::Packet::Type',
		required => 1
	);
};

package DeviceMaster::AppUtils::Daemon::Packet::Get {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::AppUtils::Daemon::Packet;

	with 'DeviceMaster::AppUtils::Daemon::Packet';

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

package DeviceMaster::AppUtils::Daemon::Packet::Set {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::AppUtils::Daemon::Packet;

	with 'DeviceMaster::AppUtils::Daemon::Packet';

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

package DeviceMaster::AppUtils::Daemon::Bridge::Item {
	use namespace::autoclean;
	use Moose;

	use Moose::Util;
	use Moose::Util::TypeConstraints;

	enum 'DeviceMaster::AppUtils::Daemon::Bridge::Item::Type' => [qw (
		DeviceSystem
		Device
		FeatureInterface
	)];

	enum 'DeviceMaster::AppUtils::Daemon::Bridge::Item::FeatureType' => [qw (
		Unset
		Generic
		FeatureChoiceInterface
		FeaturePercentageInterface
	)];

	has ref => (
		is => 'ro',
		isa => 'ScalarRef[Any]',
		required => 1
	);

	has type => (
		is => 'ro',
		isa => 'DeviceMaster::AppUtils::Daemon::Bridge::Item::Type',
		required => 1
	);

	has feature_type => (
		is => 'ro',
		isa => 'DeviceMaster::AppUtils::Daemon::Bridge::Item::FeatureType',
		default => 'Unset'
	);
};

package DeviceMaster::AppUtils::Daemon::Bridge {
	use namespace::autoclean;
	use Moose;

	has 'deviceSystem' => (
		is => 'ro',
		isa => 'DeviceMaster::DeviceSystem',
		required => 1
	);

	has '_refs' => (
		is => 'rw',
		isa => 'HashRef[DeviceMaster::AppUtils::Daemon::Bridge::Item]',
		default => sub { {} }
	);

	sub getItem {
		my $self = shift;
		my $path = shift;

		if (0 == exists $self->_refs->{$path}) {
			my $path_short = $path;
			my $path_orig = $path;

			$path =~ s#/\bFI\b/#/feature_interfaces/#g;
			$path =~ s#/\bFIV\b/#/feature_interfaces_virtual/#g;
			$path_short =~ s#/\bfeature_interfaces\b/#/FI/#g;
			$path_short =~ s#/\bfeature_interfaces_virtual\b/#/FIV/#g;

			my $ref = $self->deviceSystem->dive ($path);
			my $type;
			my $feature_type = 'Unset';

			if (Moose::Util::does_role ($$ref, 'DeviceMaster::FeatureInterface')) {
				$type = 'FeatureInterface';

				if (eval { $$ref->isa ('DeviceMaster::Virtual::FeatureChoiceInterface') }) {
					$feature_type = 'FeatureChoiceInterface';
				}
				elsif (eval { $$ref->isa ('DeviceMaster::Virtual::FeaturePercentageInterface') }) {
					$feature_type = 'FeaturePercentageInterface';
				}
				else {
					$feature_type = 'Generic';
				}
			}
			elsif (Moose::Util::does_role ($$ref, 'DeviceMaster::Device')) {
				$type = 'Device';
			}
			elsif ($$ref->isa ('DeviceMaster::DeviceSystem')) {
				$type = 'DeviceSystem';
			}

			$self->_refs->{$path} = DeviceMaster::AppUtils::Daemon::Bridge::Item->new (
				ref => $ref,
				type => $type,
				feature_type => $feature_type
			);

			if (0 == exists $self->_refs->{$path_short}) {
				$self->_refs->{$path_short} = $self->_refs->{$path};
			}

			if (0 == exists $self->_refs->{$path_orig}) {
				$self->_refs->{$path_orig} = $self->_refs->{$path};
			}
		}

		return $self->_refs->{$path};
	}
};

package DeviceMaster::Apps::Daemon {
	use MooseX::App::Command;
	use Moose;

	use IO::Socket::UNIX;
	use threads;
	use Thread::Queue;
	use JSON::XS;

	use Fcntl qw( :mode );

	use DeviceMaster::DeviceSystem;
	use DeviceMaster::Device;
	use DeviceMaster::FeatureInterface;

	use DeviceMaster::Apps;
	extends 'DeviceMaster::Apps';

	option 'path' => (
		is => 'ro',
		isa => 'Str',
		documentation => 'the socket file path',
		default => '/tmp/devicemaster.socket'
	);

	option group => (
		is => 'ro',
		documentation => 'group to own the socket file'
	);

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

	has bridge => (
		is => 'ro',
		isa => 'DeviceMaster::AppUtils::Daemon::Bridge',
		default => sub {
			return DeviceMaster::AppUtils::Daemon::Bridge->new (
				deviceSystem => DeviceMaster::DeviceSystem->new
			);
		}
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
		my $cmd = shift;

		my $item = $self->bridge->getItem ($cmd->path);

		my $r;

		if ('Get' eq $cmd->type) {
			if ('FeatureInterface' eq $item->type) {
				$r = { response => ${$item->ref}->acquire, success => 1 };
				if ('FeatureChoiceInterface' eq $item->feature_type) {
					$r->{choices} = [ split ' ', ${${$item->ref}->choices}->acquire ];
				}
				elsif ('FeaturePercentageInterface' eq $item->feature_type) {
					$r->{lower_bound} = ${${$item->ref}->lower_bound}->acquire;
					$r->{upper_bound} = ${${$item->ref}->upper_bound}->acquire;
				}
			}
			elsif (
				'DeviceSystem' eq $item->type || 'Device' eq $item->type
			) {
				$r = { response => ${$item->ref}->pack, success => 1 };
			}
			else {
				$r = { response => '', success => 0, error => 'invalid data requested' };
			}
		}
		elsif ('Set' eq $cmd->type) {
			if ('FeatureInterface' eq $item->type) {
				if (${$item->ref}->set ($cmd->value)) {
					$r = { response => ${$item->ref}->acquire, success => 1 };
				}
				else {
					$r = { response => ${$item->ref}->acquire, success => 0, error => 'failed to set the value' };
				}
			}
			else {
				$r = { response => '', success => 0, error => 'invalid feature requested to set a value' };
			}
		}
		else {
			$r = { response => '', success => 0, error => 'invalid request type' };
		}

		return $r;
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
						my $packet = DeviceMaster::AppUtils::Daemon::Packet::Get->new (
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
						my $packet = DeviceMaster::AppUtils::Daemon::Packet::Set->new (
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
			while (my $cmd = $self->cmd_q->dequeue) {
				$self->res_q->enqueue ($self->_process_command ($cmd));
			}
		});
	}

	sub run {
		my $self = shift;

		if (-S $self->path) {
			unlink $self->path;
		}

		$self->server;

		chmod S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP, $self->path;

		if (defined $self->group) {
			# chgrp group path - the most complicated way possible:
			chown ((stat ($self->path)) [4], (getgrnam ($self->group)) [2], $self->path);
		}

		$self->listen;
	}
}

1;

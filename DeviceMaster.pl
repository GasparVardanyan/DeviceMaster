#!/usr/bin/env perl

use strict;
use warnings;

use lib '.';

package DeviceMaster::App {
	use MooseX::App;
}

package DeviceMaster::App::JRPC {
	use MooseX::App::Command;

	use Fcntl qw( :mode );

	use DeviceMaster::Apps::JRPC;
	extends 'DeviceMaster::App';

	option 'socket_file' => (
		is => 'ro',
		isa => 'Str',
		documentation => 'the socket file path',
		default => '/tmp/devicemaster.socket'
	);

	option group => (
		is => 'ro',
		documentation => 'group to own the socket file'
	);

	has jrpc => (
		is => 'ro',
		isa => 'DeviceMaster::Apps::JRPC',
		default => sub {
			my $self = shift;

			return DeviceMaster::Apps::JRPC->new (
				path => $self->socket_file
			);
		},
		lazy => 1
	);

	sub run {
		my $self = shift;

		if (-S $self->socket_file) {
			unlink $self->socket_file;
		}

		$self->jrpc->server;

		chmod S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP, $self->socket_file;

		if (defined $self->group) {
			# chgrp group socket_file - the most complicated way possible:
			chown ((stat ($self->socket_file)) [4], (getgrnam ($self->group)) [2], $self->socket_file);
		}

		$self->jrpc->listen;
	}
}

DeviceMaster::App->new_with_command->run;

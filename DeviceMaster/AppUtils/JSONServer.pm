use strict;
use warnings;

package DeviceMaster::AppUtils::JSONServer {
	use namespace::autoclean;
	use Moo::Role;

	use Types::Standard ();

	use Fcntl ();
	use threads ();
	use Thread::Queue ();
	use IO::Socket::UNIX ();
	use JSON::XS ();

	requires 'process_command';

	has path => (
		is => 'ro',
		isa => Types::Standard::Str,
		# documentation => 'the socket file path',
		default => '/tmp/devicemaster.socket'
	);

	has group => (
		is => 'ro',
		# documentation => 'group to own the socket file'
	);

	has server => (
		is => 'ro',
		# isa => Types::Standard::ScalarRef[Types::Standard::InstanceOf['IO::Socket::UNIX']],
		init_arg => undef,
		default => sub {
			my $self = shift;
			return IO::Socket::UNIX->new (
				Type => IO::Socket::UNIX::SOCK_STREAM,
				Local => $self->path,
				Listen => 5
			);
		},
		lazy => 1
	);

	has json => (
		is => 'rw',
		# isa => Types::Standard::ScalarRef[Types::Standard::InstanceOf['JSON::XS']],
		init_arg => undef,
		default => sub { JSON::XS->new->utf8->canonical; }
	);

	has command_q => (
		is => 'ro',
		# isa => Types::Standard::ScalarRef[Types::Standard::InstanceOf['Thread::Queue']],
		init_arg => undef,
		default => sub {
			Thread::Queue->new;
		}
	);

	sub listen {
		my $self = shift;
		while (my $client = $self->server->accept) {
			threads->create (sub {
				my $result_q = Thread::Queue->new;

				while (my $cmd = <$client>) {
					chomp $cmd;
					last unless defined $cmd;

					my $r = { response => '', success => 0, error => 'invalid json' };
					my $j = eval { $self->json->decode ($cmd) };
					if (!$@) {
						$self->command_q->enqueue ([ $result_q, $j ]);
						$r = $result_q->dequeue;
					}

					$client->print ($self->json->encode ($r), "\n");
				}

				$client->close;
			})->detach;
		}
	}

	sub BUILD {
		my $self = shift;

		threads->create (sub {
			while (1) {
				my $task = $self->command_q->dequeue;
				my ($client_q, $cmd) = @$task;

				my $result = $self->process_command ($cmd);

				$client_q->enqueue ($result);
			}
		});
	}

	sub run {
		my $self = shift;

		if (-S $self->path) {
			unlink $self->path;
		}

		$self->server;

		chmod Fcntl::S_IRUSR|Fcntl::S_IWUSR|Fcntl::S_IRGRP|Fcntl::S_IWGRP, $self->path;

		if (defined $self->group) {
			# chgrp group path - the most complicated way possible:
			chown ((stat ($self->path)) [4], (getgrnam ($self->group)) [2], $self->path);
		}

		$self->listen;
	}
}

1;

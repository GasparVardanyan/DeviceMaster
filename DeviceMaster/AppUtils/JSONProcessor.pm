use strict;
use warnings;

package DeviceMaster::AppUtils::JSONProcessor {
	use namespace::autoclean;
	use Moo;

	use DeviceMaster::AppUtils::PacketProcessor;
	use DeviceMaster::AppUtils::Packet;

	has packet_processor => (
		is => 'ro',
		isa => Types::Standard::InstanceOf['DeviceMaster::AppUtils::PacketProcessor'],
		default => sub {
			return DeviceMaster::AppUtils::PacketProcessor->new;
		}
	);

	sub process {
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

				my $return_path = (exists $j->{return_path} && $j->{return_path}) ? 1 : 0;

				if ('Get' eq $type) {
					if (exists $j->{path}) {
						my $packet = DeviceMaster::AppUtils::Packet::Get->new (
							path => $self->sanitize_path ($j->{path}),
							return_path => $return_path
						);

						$r = $self->packet_processor->process ($packet);
					}
					else {
						$r->{error} = 'Get request must have a path';
					}
				}
				elsif ('Set' eq $type) {
					if (exists $j->{path} && exists $j->{value}) {
						my $packet = DeviceMaster::AppUtils::Packet::Set->new (
							path => $self->sanitize_path ($j->{path}),
							value => $j->{value},
							return_path => $return_path
						);

						$r = $self->packet_processor->process ($packet);
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
					$self->process ($_)
				} @$j
			];

			return $r;
		}
		else {
			return { response => '', success => 0, error => 'invalid json signature' };
		}
	}

	sub sanitize_path {
		my $self = shift;
		my $path = shift;
		$path =~ s/\s+//g;
		$path =~ s/\/+/\//g;

		if ('/' ne $path) {
			$path =~ s/\/$//;
		}

		return $path;
	}

	__PACKAGE__->meta->make_immutable;
};

1;

use strict;
use warnings;

package DeviceMaster::AppUtils::PacketProcessor {
	use namespace::autoclean;
	use Moo;

	use DeviceMaster::DeviceSystem;
	use DeviceMaster::AppUtils::Packet;
	use DeviceMaster::AppUtils::PathBridge;

	has deviceSystem => (
		is => 'ro',
		isa => Types::Standard::ScalarRef[Types::Standard::InstanceOf['DeviceMaster::DeviceSystem']],
		required => 1
	);

	has path_bridge => (
		is => 'ro',
		isa => Types::Standard::ScalarRef[Types::Standard::InstanceOf['DeviceMaster::AppUtils::PathBridge']],
		default => sub {
			my $self = shift;
			return \DeviceMaster::AppUtils::PathBridge->new (
				deviceSystem => $self->deviceSystem
			);
		},
		lazy => 1
	);

	sub process {
		my $self = shift;
		my $cmd = shift;

		my $item = ${$self->path_bridge}->getItem ($cmd->path);

		my $r;

		if ('Get' eq $cmd->type) {
			if ('FeatureInterface' eq $item->type) {
				$r = { response => ${$item->ref}->acquire, success => 1 };
				if ('FeatureChoiceInterface' eq $item->feature_type) {
					$r->{choices} = [ split ' ', ${${$item->ref}->choices}->acquire ];
				}
				elsif ('FeaturePercentageInterface' eq $item->feature_type) {
					$r->{lower_bound} = 0 + ${${$item->ref}->lower_bound}->acquire;
					$r->{upper_bound} = 0 + ${${$item->ref}->upper_bound}->acquire;
					$r->{response} = 0 + $r->{response};
				}
			}
			elsif (
				'DeviceSystem' eq $item->type || 'Device' eq $item->type
			) {
				$r = { response => ${$item->ref}, success => 1 };
			}
			elsif ('HASH' eq $item->type) {
				$r = { response => {
					map {
						$_ => $self->process (DeviceMaster::AppUtils::Packet::Get->new (
							path => $cmd->path . "/$_"
						))->{response} # NOTE: this takes only the actual value
					} keys %${$item->ref}
				}, success => 1 };
			}
			else {
				$r = { response => '', success => 0, error => 'invalid data requested' };
			}
		}
		elsif ('Set' eq $cmd->type) {
			if ('FeatureInterface' eq $item->type) {
				if (${$item->ref}->set ($cmd->value)) {
					$r = { response => ${$item->ref}->get, success => 1 };
				}
				else {
					$r = { response => ${$item->ref}->get, success => 0, error => 'failed to set the value' };
				}
			}
			else {
				$r = { response => '', success => 0, error => 'invalid feature requested to set a value' };
			}
		}
		elsif ('Ensure' eq $cmd->type) {
			if ('FeatureInterface' eq $item->type) {
				if (${$item->ref}->ensure ($cmd->value)) {
					$r = { response => ${$item->ref}->get, success => 1 };
				}
				else {
					$r = { response => ${$item->ref}->get, success => 0, error => 'failed to set the value' };
				}
			}
			else {
				$r = { response => '', success => 0, error => 'invalid feature requested to set a value' };
			}
		}
		else {
			$r = { response => '', success => 0, error => 'invalid request type' };
		}

		if (1 == $cmd->return_path) {
			$r->{path} = $cmd->path;
		}

		return $r;
	}

	__PACKAGE__->meta->make_immutable;
}

1;

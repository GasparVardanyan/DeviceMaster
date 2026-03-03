use strict;
use warnings;

package DeviceMaster::AppUtils::PacketProcessor {
	use namespace::autoclean;
	use Moo;

	use DeviceMaster::AppUtils::PathBridge;

	has path_bridge => (
		is => 'ro',
		# isa => Types::Standard::ScalarRef[Types::Standard::InstanceOf['DeviceMaster::AppUtils::PathBridge']],
		default => sub {
			return DeviceMaster::AppUtils::PathBridge->new (
				deviceSystem => DeviceMaster::DeviceSystem->new
			);
		}
	);

	sub process {
		my $self = shift;
		my $cmd = shift;

		my $item = $self->path_bridge->getItem ($cmd->path);

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
			elsif ('HASH' eq $item->type) {
				$r = { response => {
					map {
						$_ => $self->process (DeviceMaster::AppUtils::Packet::Get->new (
							path => $cmd->path . "/$_"
						))->{response}
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

	__PACKAGE__->meta->make_immutable;
}

1;

use strict;
use warnings;

package DeviceMaster::AppUtils::PathBridge::Item {
	use namespace::autoclean;
	use Moo;

	use Types::Standard ();

	# use Moose::Util;
	# use Moose::Util::TypeConstraints;

	# enum 'DeviceMaster::AppUtils::Daemon::Bridge::Item::Type' => [qw (
	# 	DeviceSystem
	# 	Device
	# 	FeatureInterface
	# 	HASH
	# 	Undef
	# )];
	#
	# enum 'DeviceMaster::AppUtils::Daemon::Bridge::Item::FeatureType' => [qw (
	# 	Unset
	# 	Generic
	# 	FeatureChoiceInterface
	# 	FeaturePercentageInterface
	# )];

	has ref => (
		is => 'ro',
		isa => Types::Standard::ScalarRef[Types::Standard::Any],
		required => 1
	);

	has type => (
		is => 'ro',
		# isa => 'DeviceMaster::AppUtils::Daemon::Bridge::Item::Type',
		required => 1
	);

	has feature_type => (
		is => 'ro',
		# isa => 'DeviceMaster::AppUtils::Daemon::Bridge::Item::FeatureType',
		default => 'Unset'
	);

	__PACKAGE__->meta->make_immutable;
};

package DeviceMaster::AppUtils::PathBridge {
	use namespace::autoclean;
	use Moo;

	use Types::Standard ();

	use DeviceMaster::AppUtils::PathBridge::Item;
	use DeviceMaster::Device;
	use DeviceMaster::DeviceSystem;
	use DeviceMaster::FeatureInterface;
	use DeviceMaster::Virtual::FeatureChoiceInterface;
	use DeviceMaster::Virtual::FeaturePercentageInterface;

	has deviceSystem => (
		is => 'ro',
		isa => Types::Standard::ScalarRef[Types::Standard::InstanceOf['DeviceMaster::DeviceSystem']],
		required => 1
	);

	has _refs => (
		is => 'rw',
		isa => Types::Standard::HashRef[Types::Standard::InstanceOf['DeviceMaster::AppUtils::PathBridge::Item']],
		init_arg => undef,
		default => sub { {} }
	);

	sub getItem {
		my $self = shift;
		my $path = shift;

		if (0 == exists $self->_refs->{$path}) {
			my $path_short = $path;
			my $path_orig = $path;

			$path =~ s/\bFI\b/feature_interfaces/g;
			$path =~ s/\bFIV\b/feature_interfaces_virtual/g;
			$path_short =~ s/\bfeature_interfaces\b/FI/g;
			$path_short =~ s/\bfeature_interfaces_virtual\b/FIV/g;

			my $ref = ${$self->deviceSystem}->dive ($path);
			my $type;
			my $feature_type = 'Unset';

			if (defined $$ref) {
				if (eval { $$ref->does ('DeviceMaster::FeatureInterface') }) {
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
				elsif (eval { $$ref->does ('DeviceMaster::Device') }) {
					$type = 'Device';
				}
				elsif (eval { $$ref->isa ('DeviceMaster::DeviceSystem') }) {
					$type = 'DeviceSystem';
				}
				elsif ('HASH' eq ref $$ref) {
					$type = 'HASH';
				}
			}
			else {
				$type = 'Undef';
			}

			$self->_refs->{$path} = DeviceMaster::AppUtils::PathBridge::Item->new (
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

	__PACKAGE__->meta->make_immutable;
};

1;

use strict;
use warnings;

package DeviceMaster::Virtual::FeatureVirtual {
	use namespace::autoclean;
	use Moo;

	use List::Util ();

	use DeviceMaster::Feature;
	with 'DeviceMaster::Feature';

	has dependencies => ( is => 'ro', isa => Types::Standard::ArrayRef[Types::Standard::Str], required => 1 );
	has generate => ( is => 'ro', isa => Types::Standard::CodeRef, required => 1 );
	has dependency_resolver => ( is => 'ro', isa => Types::Standard::CodeRef );

	sub supports {
		my $self = shift;
		my $device = shift;

		if (defined $self->dependency_resolver) {
			return $self->dependency_resolver->($device, $self);
		}
		else {
			return List::Util::all { exists $device->feature_interfaces->{$_} } @{ $self->dependencies };
		}
	}

	sub make_interface {
		my $self = shift;
		my $device = shift;

		return $self->generate->($device);
	}

	__PACKAGE__->meta->make_immutable;
}

package DeviceMaster::Virtual::FeatureVirtual::DependencyResolver {
	sub Dependencies {
		my $feature = shift;
		my $where = shift;

		return List::Util::all { exists $where->{$_} } @{ $feature->dependencies };
	}

	sub DeviceDependencies {
		my $device = shift;
		my $feature = shift;
		my $where = shift;

		return DeviceMaster::Virtual::FeatureVirtual::DependencyResolver::Dependencies (
			$feature, $device->$where
		);
	}

	sub FeatureDependencies {
		my $device = shift;
		my $feature = shift;

		return DeviceMaster::Virtual::FeatureVirtual::DependencyResolver::Dependencies (
			$feature, $device->feature_interfaces
		);
	}

	sub VirtualFeatureDependencies {
		my $device = shift;
		my $feature = shift;

		return DeviceMaster::Virtual::FeatureVirtual::DependencyResolver::Dependencies (
			$feature, $device->feature_interfaces_virtual
		);
	}

	sub CompoundDependencies {
		my $device = shift;
		my $feature = shift;
		my $compound = shift;
		my $where = shift;

		return List::Util::all {
			DeviceMaster::Virtual::FeatureVirtual::DependencyResolver::Dependencies (
				$feature, $compound->{ $_ }->$where
			)
		} keys %{ $compound };
	}
};

1;

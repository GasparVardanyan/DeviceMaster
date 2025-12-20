use strict;
use warnings;

package DeviceMaster::Device {
	use namespace::autoclean;
	use Moose::Role;

	with 'DeviceMaster::Utils::Serializable';

	has id => ( is => 'ro', isa => 'Str' );
	has feature_interfaces => (
		is => 'ro',
		isa => 'HashRef[DeviceMaster::FeatureInterface]',
		init_arg => undef,
		default => sub { {} }
	);
	has feature_interfaces_virtual => (
		is => 'ro',
		isa => 'HashRef[DeviceMaster::FeatureInterface]',
		init_arg => undef,
		default => sub { {} },
		lazy => 1
	);
	has dir => (
		is => 'ro',
		isa => 'Str',
		default => '',
		traits => ['DoNotSerialize']
	);

	has Features => (
		is => 'ro',
		isa => 'HashRef[DeviceMaster::Feature]',
		traits => ['DoNotSerialize'],
		init_arg => undef,
		default => sub { {} }
	);

	has FeaturesVirtual => (
		is => 'ro',
		isa => 'HashRef[DeviceMaster::Virtual::FeatureVirtual]',
		traits => ['DoNotSerialize'],
		init_arg => undef,
		default => sub { {} }
	);

	before BUILD => sub {
		my $self = shift;

		my %_F = %{ $self->Features };

		for my $feature_name (keys %_F) {
			my $feature = $_F {$feature_name};

			if ($feature->supports ($self)) {
				my $feature_name = $feature->name;

				$self->feature_interfaces->{$feature_name} = $feature->make_interface ($self);
			}
		}

		%_F = %{ $self->FeaturesVirtual };

		for my $feature_virtual_name (keys %_F) {
			my $feature_virtual = $_F {$feature_virtual_name};

			if ($feature_virtual->supports ($self)) {
				my $feature_name = $feature_virtual->name;

				$self->feature_interfaces_virtual->{$feature_name} = $feature_virtual->make_interface ($self);
			}
		}
	};

	sub BUILD { }

	sub acquire {
		my $self = shift;
		my $feature = shift;

		return $self->feature_interfaces->{$feature}->acquire;
	}

	sub get {
		my $self = shift;
		my $feature = shift;

		return $self->feature_interfaces->{$feature}->get;
	}

	sub set {
		my $self = shift;
		my $feature = shift;
		my $value = shift;

		return $self->feature_interfaces->{$feature}->set ($value);
	}

	sub supports {
		my $self = shift;
		my $feature = shift;

		return grep { $_ eq $feature } keys %{$self->feature_interfaces};
	}

	sub writable {
		my $self = shift;
		my $feature = shift;

		return $self->feature_interfaces->{$feature}->writable;
	}

	sub readable {
		my $self = shift;
		my $feature = shift;

		return $self->feature_interfaces->{$feature}->readable;
	}
}

1;

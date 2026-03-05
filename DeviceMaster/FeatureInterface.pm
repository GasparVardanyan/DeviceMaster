use strict;
use warnings;

package DeviceMaster::FeatureInterface {
	use namespace::autoclean;
	use Moo::Role;

	use DeviceMaster::Utils::Serializable;
	sub _serializable_attributes { ['readable', 'writable']; }
	with 'DeviceMaster::Utils::Serializable';

	requires 'read';
	requires 'write';

	has value => (
		is => 'rw',
		isa => Types::Standard::Str,
		traits => ['DoNotSerialize']
	);

	has readable => ( is => 'ro', isa => Types::Standard::Bool, required => 1 );
	has writable => ( is => 'ro', isa => Types::Standard::Bool, required => 1 );

	sub acquire {
		my $self = shift;

		$self->value ($self->read);

		return $self->value;
	}

	sub get {
		my $self = shift;
		return $self->value;
	}

	sub set {
		my $self = shift;
		my $value = shift;

		$self->write ($value);

		$self->acquire;

		return $self->value eq $value;
	}
}

1;

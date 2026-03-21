use strict;
use warnings;

package DeviceMaster::Virtual::FeatureConstantInterface {
	use namespace::autoclean;
	use Moo;

	use DeviceMaster::FeatureInterface;

	sub read {
		my $self = shift;
		return $self->value;
	}

	sub write {
		my $self = shift;
		return $self->value;
	}

	with 'DeviceMaster::FeatureInterface';

	has '+readable' => (
		init_arg => undef,
		default => sub { 1 }
	);
	has '+writable' => (
		init_arg => undef,
		default => sub { 0 }
	);
	has '+value' => ( required => 1 );

	our $Zero = DeviceMaster::Virtual::FeatureConstantInterface->new ( value => 0 );
	our $One = DeviceMaster::Virtual::FeatureConstantInterface->new ( value => 1 );
	our $Hundred = DeviceMaster::Virtual::FeatureConstantInterface->new ( value => 100 );

	__PACKAGE__->meta->make_immutable;
};

1;

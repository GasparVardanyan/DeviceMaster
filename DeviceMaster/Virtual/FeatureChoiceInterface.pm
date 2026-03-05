use strict;
use warnings;

package DeviceMaster::Virtual::FeatureChoiceInterface {
	use namespace::autoclean;
	use Moo;

	use DeviceMaster::FeatureInterface;
	use DeviceMaster::Virtual::FeatureConstantInterface;
	use DeviceMaster::Types;

	has choices => (
		is => 'ro',
		isa => Types::Standard::ScalarRef[Types::Standard::ConsumerOf['DeviceMaster::FeatureInterface']],
		required => 1,
	);

	has target => (
		is => 'ro',
		isa => Types::Standard::ScalarRef[Types::Standard::ConsumerOf['DeviceMaster::FeatureInterface']],
		required => 1,
	);

	sub read {
		my $self = shift;

		return ${$self->target}->acquire;
	}

	sub write {
		my $self = shift;
		my $value = shift;

		if (grep { $_ eq $value } split ' ', ${$self->choices}->acquire) {
			return ${$self->target}->set ($value);
		}
		else {
			return 0;
		}
	}

	with 'DeviceMaster::FeatureInterface';

	has '+readable' => (
		init_arg => undef,
		default => sub {
			my $self = shift;
			return ${$self->target}->readable;
		},
		lazy => 1
	);
	has '+writable' => (
		init_arg => undef,
		default => sub {
			my $self = shift;
			return ${$self->target}->writable
		},
		lazy => 1
	);

	our $Boolean = DeviceMaster::Virtual::FeatureConstantInterface->new (
		value => '0 1'
	);

	__PACKAGE__->meta->make_immutable;
}

1;

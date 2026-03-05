use strict;
use warnings;

package DeviceMaster::Virtual::FeaturePercentageInterface {
	use namespace::autoclean;
	use Moo;
	use Types::Standard ();

	use DeviceMaster::FeatureInterface;
	use DeviceMaster::Types;

	has lower_bound => (
		is => 'ro',
		isa => Types::Standard::ScalarRef[Types::Standard::ConsumerOf['DeviceMaster::FeatureInterface']],
		required => 1,
	);

	has upper_bound => (
		is => 'ro',
		isa => Types::Standard::ScalarRef[Types::Standard::ConsumerOf['DeviceMaster::FeatureInterface']],
		required => 1,
	);

	has target => (
		is => 'ro',
		isa => Types::Standard::ScalarRef[Types::Standard::ConsumerOf['DeviceMaster::FeatureInterface']],
		required => 1,
	);

	has _write_status => (
		is => 'rw',
		isa => Types::Standard::Bool,
		init_arg => undef,
	);

	sub read {
		my $self = shift;

		# (u - l) * p / 100 + l = t
		# p = (t - l) * 100 / (u - l)

		my $u = ${$self->upper_bound}->acquire;
		my $l = ${$self->lower_bound}->acquire;
		my $t = ${$self->target}->acquire;

		return DeviceMaster::Types::MakePercentage (($t - $l) * 100 / ($u - $l));
	}

	sub write {
		my $self = shift;
		my $p = shift;
		$p = DeviceMaster::Types::MakePercentage ($p);
		my $u = ${$self->upper_bound}->acquire;
		my $l = ${$self->lower_bound}->acquire;

		if ($DeviceMaster::Virtual::FeatureConstantInterface::Hundred == $p) {
			$self->_write_status (${$self->target}->set ($u));
		}
		elsif ($DeviceMaster::Virtual::FeatureConstantInterface::Zero == $p) {
			$self->_write_status (${$self->target}->set ($l));
		}
		else {
			$self->_write_status (
				${$self->target}->set (DeviceMaster::Types::BoundInt ($l + ($u - $l) * $p / 100, $l, $u))
			);
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

	has '+value' => (
		isa => DeviceMaster::Types::Percentage ()
	);

	around set => sub {
		my $orig = shift;
		my $self = shift;
		my $value = shift;

		$self->$orig ($value);

		return $self->_write_status;
	};

	__PACKAGE__->meta->make_immutable;
}

1;

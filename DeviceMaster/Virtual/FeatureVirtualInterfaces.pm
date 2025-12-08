use strict;
use warnings;

package DeviceMaster::Virtual::FeatureConstantInterface {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::FeatureInterface;
	use DeviceMaster::Utils::Serializable;

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
	our $Hundred = DeviceMaster::Virtual::FeatureConstantInterface->new ( value => 100 );
};

package DeviceMaster::Virtual::FeaturePercentageInterface {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::FeatureInterface;
	use DeviceMaster::Utils::Serializable;
	use DeviceMaster::Types;

	with 'DeviceMaster::Utils::Serializable';

	has lower_bound => (
		is => 'ro',
		isa => 'ScalarRef[DeviceMaster::FeatureInterface]',
		traits => ['DoNotSerialize'],
		required => 1,
	);

	has upper_bound => (
		is => 'ro',
		isa => 'ScalarRef[DeviceMaster::FeatureInterface]',
		traits => ['DoNotSerialize'],
		required => 1,
	);

	has target => (
		is => 'ro',
		isa => 'ScalarRef[DeviceMaster::FeatureInterface]',
		traits => ['DoNotSerialize'],
		required => 1,
	);

	has _value_read => (
		is => 'rw',
		isa => 'Int',
		init_arg => undef,
		traits => ['DoNotSerialize']
	);

	has _value_write => (
		is => 'rw',
		isa => 'Int',
		init_arg => undef,
		traits => ['DoNotSerialize']
	);

	sub read {
		my $self = shift;

		# (u - l) * p / 100 + l = t
		# p = (t - l) * 100 / (u - l)

		my $u = ${$self->upper_bound}->acquire;
		my $l = ${$self->lower_bound}->acquire;
		my $t = ${$self->target}->acquire;

		$self->_value_read ($t);

		return DeviceMaster::Types::MakePercentage (($t - $l) * 100 / ($u - $l));
	}

	sub write {
		my $self = shift;
		my $p = shift;
		$p = DeviceMaster::Types::MakePercentage ($p);
		my $u = ${$self->upper_bound}->acquire;
		my $l = ${$self->lower_bound}->acquire;

		if ($DeviceMaster::Virtual::FeatureConstantInterface::Hundred == $p) {
			$self->_value_write ($u);
		}
		elsif ($DeviceMaster::Virtual::FeatureConstantInterface::Zero == $p) {
			$self->_value_write ($l);
		}
		else {
			$self->_value_write (DeviceMaster::Types::BoundInt ($l + ($u - $l) * $p / 100, $l, $u));
		}

		${$self->target}->set ($self->_value_write);
	}

	with 'DeviceMaster::FeatureInterface';

	has '+value' => (
		isa => 'DeviceMaster::Types::Percentage'
	);

	around set => sub {
		my $orig = shift;
		my $self = shift;
		my $value = shift;

		$self->$orig ($value);

		return $self->_value_read == $self->_value_write;
	};
}

package DeviceMaster::Virtual::FeatureCompoundInterface {
	use namespace::autoclean;
	use Moose;

	use List::Util;

	use DeviceMaster::FeatureInterface;
	use DeviceMaster::Utils::Serializable;
	use DeviceMaster::Types;

	with 'DeviceMaster::Utils::Serializable';

	has targets => (
		is => 'ro',
		isa => 'HashRef[ScalarRef[DeviceMaster::FeatureInterface]]',
		traits => ['DoNotSerialize'],
		required => 1,
	);

	sub read {
		my $self = shift;

		return {
			map {
				$_ => ${$self->targets->{$_}}->acquire
			} keys %{ $self->targets }
		};
	}

	sub write {
		my $self = shift;
		my $value = shift;

		my %_T = %{ $self->targets };

		for my $fname (keys %_T) {
			my $fref = $_T {$fname};
			${$fref}->set ($value);
		}
	}

	with 'DeviceMaster::FeatureInterface';

	has '+value' => (
		isa => 'HashRef[Str]'
	);

	around set => sub {
		my $orig = shift;
		my $self = shift;
		my $value = shift;

		$self->$orig ($value);

		return List::Util::all { $_ eq $value } values %{ $self->value };
	};
}

1;

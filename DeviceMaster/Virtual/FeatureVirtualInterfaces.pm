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

	has _write_status => (
		is => 'rw',
		isa => 'Bool',
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
		isa => 'DeviceMaster::Types::Percentage'
	);

	around set => sub {
		my $orig = shift;
		my $self = shift;
		my $value = shift;

		$self->$orig ($value);

		return $self->_write_status;
	};
}

package DeviceMaster::Virtual::FeatureCompoundInterface {
	use namespace::autoclean;
	use Moose;

	use List::Util ();

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

	has _write_status => (
		is => 'rw',
		isa => 'HashRef[Bool]',
		init_arg => undef,
		traits => ['DoNotSerialize'],
		default => sub { {} }
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
			$self->_write_status->{$fname} = ${$_T {$fname}}->set ($value);
		}
	}

	with 'DeviceMaster::FeatureInterface';

	has '+value' => (
		isa => 'HashRef[Str]'
	);

	has '+readable' => (
		init_arg => undef,
		default => sub {
			my $self = shift;
			my @status_arr = List::Util::uniq map { ${$self->targets->{$_}}->readable } keys %{ $self->targets };
			if (@status_arr != 1) {
				die "All features interfaces in the virtual compount interface must possess the same readability state";
			}
			return $status_arr[0];
		},
		lazy => 1
	);

	has '+writable' => (
		init_arg => undef,
		default => sub {
			my $self = shift;
			my @status_arr = List::Util::uniq map { ${$self->targets->{$_}}->writable } keys %{ $self->targets };
			if (@status_arr != 1) {
				die "All features interfaces in the virtual compount interface must possess the same writablity state";
			}
			return $status_arr[0];
		},
		lazy => 1
	);

	around set => sub {
		my $orig = shift;
		my $self = shift;
		my $value = shift;

		$self->$orig ($value);

		return List::Util::all { $_ eq 1 } values %{ $self->_write_status };
	};
}

package DeviceMaster::Virtual::FeatureChoiceInterface {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::FeatureInterface;
	use DeviceMaster::Utils::Serializable;
	use DeviceMaster::Types;

	with 'DeviceMaster::Utils::Serializable';

	has choices => (
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
}

1;

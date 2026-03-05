use strict;
use warnings;

package DeviceMaster::Virtual::FeatureCompoundInterface {
	use namespace::autoclean;
	use Moo;

	use Types::Standard;

	use List::Util ();

	use DeviceMaster::FeatureInterface;
	use DeviceMaster::Types;

	has targets => (
		is => 'ro',
		isa => Types::Standard::HashRef[Types::Standard::ScalarRef[Types::Standard::ConsumerOf['DeviceMaster::FeatureInterface']]],
		required => 1,
	);

	has _write_status => (
		is => 'rw',
		isa => Types::Standard::HashRef[Types::Standard::Bool],
		init_arg => undef,
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
		isa => Types::Standard::HashRef[Types::Standard::Str]
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

	__PACKAGE__->meta->make_immutable;
}

1;

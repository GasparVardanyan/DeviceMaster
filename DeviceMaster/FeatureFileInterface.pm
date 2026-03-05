use strict;
use warnings;

package DeviceMaster::FeatureFileInterface {
	use namespace::autoclean;
	use Moo;

	with 'DeviceMaster::FeatureInterface';

	use DeviceMaster::Utils;

	has path => (
		is => 'ro',
		isa => Types::Standard::Str,
		traits => ['DoNotSerialize'],
		required => 1
	);

	sub read {
		my $self = shift;

		return DeviceMaster::Utils::read_sys_file ($self->path);
	}

	sub write {
		my $self = shift;
		my $value = shift;

		DeviceMaster::Utils::write_sys_file (
			$self->path,
			$value
		);
	}

	__PACKAGE__->meta->make_immutable;
}

1;

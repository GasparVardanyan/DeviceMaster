use strict;
use warnings;

package DeviceMaster::FeatureFileInterface {
	use namespace::autoclean;
	use Moo;

	use Types::Standard ();

	with 'DeviceMaster::FeatureInterface';

	use DeviceMaster::Utils;

	use Time::HiRes ();

	has path => (
		is => 'ro',
		isa => Types::Standard::Str,
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

		Time::HiRes::usleep 10000;
	}

	__PACKAGE__->meta->make_immutable;
}

1;

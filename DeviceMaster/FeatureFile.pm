use strict;
use warnings;

package DeviceMaster::FeatureFile::FilePath {
	sub Basic {
		my $device = shift;
		my $feature = shift;

		return $device->dir . $feature->name;
	}
}

package DeviceMaster::FeatureFile {
	use namespace::autoclean;
	use Moo;

	use Fcntl ();

	use DeviceMaster::Feature;
	with 'DeviceMaster::Feature';

	use DeviceMaster::FeatureFileInterface;

	has path_func => ( is => 'ro', isa => Types::Standard::CodeRef);

	sub supports {
		my $self = shift;
		my $device = shift;

		return -f $self->file ($device);
	}

	sub file {
		my $self = shift;
		my $device = shift;

		if (defined $self->path_func) {
			return $self->path_func->($device, $self);
		}
		else {
			return $device->dir . $self->name;
		}
	}

	sub make_interface {
		my $self = shift;
		my $device = shift;

		my $file = $self->file ($device);
		my $mode = (stat ($file)) [2];
		my $user_w = ($mode & Fcntl::S_IWUSR);
		my $user_r = ($mode & Fcntl::S_IRUSR);
		my $writable = (0 != $user_w);
		my $readable = (0 != $user_r);

		return DeviceMaster::FeatureFileInterface->new (
			path => $file,
			readable => $readable,
			writable => $writable
		);
	}

	__PACKAGE__->meta->make_immutable;
}

1;

use strict;
use warnings;

package DeviceMaster::Feature {
	use namespace::autoclean;
	use Moose::Role;

	has name => ( is => 'ro', isa => 'Str', required => 1 );

	requires 'supports';
	requires 'make_interface';
}

package DeviceMaster::FeatureFile {
	use namespace::autoclean;
	use Moose;

	with 'DeviceMaster::Feature';

	use Fcntl ();

	has path_func => ( is => 'ro', isa => 'CodeRef' );

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
}

package DeviceMaster::FeatureFile::FilePath {
	sub Basic {
		my $device = shift;
		my $feature = shift;

		return $device->dir . $feature->name;
	}
}

package DeviceMaster::FeatureInterface {
	use namespace::autoclean;
	use Moose::Role;

	requires 'read';
	requires 'write';

	has value => (
		is => 'rw',
		isa => 'Str',
		traits => ['DoNotSerialize']
	);

	has readable => ( is => 'ro', isa => 'Bool', required => 1 );
	has writable => ( is => 'ro', isa => 'Bool', required => 1 );

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

package DeviceMaster::FeatureFileInterface {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::Utils::Serializable;

	with 'DeviceMaster::Utils::Serializable';

	with 'DeviceMaster::FeatureInterface';

	use DeviceMaster::Utils;

	has path => (
		is => 'ro',
		isa => 'Str',
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
}

1;

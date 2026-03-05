use strict;
use warnings;

# TODO: DeviceMaster::AppUtils::Packet::Response

package DeviceMaster::AppUtils::Packet {
	use namespace::autoclean;
	use Moo::Role;

	use Types::Standard ();
	# use Moose::Util;
	# use Moose::Util::TypeConstraints;

	# enum 'DeviceMaster::AppUtils::Daemon::Packet::Type' => [ 'Get', 'Set' ];

	has type => (
		is => 'ro',
		# isa => 'DeviceMaster::AppUtils::Daemon::Packet::Type',
		required => 1
	);

	has return_path => (
		is => 'ro',
		isa => Types::Standard::Bool,
		default => sub { 0 }
	);
};

package DeviceMaster::AppUtils::Packet::Get {
	use namespace::autoclean;
	use Moo;

	use Types::Standard ();

	use DeviceMaster::AppUtils::Packet;

	with 'DeviceMaster::AppUtils::Packet';

	has '+type' => (
		init_arg => undef,
		default => sub { 'Get' }
	);

	has path => (
		is => 'ro',
		isa => Types::Standard::Str,
		required => 1
	);

	__PACKAGE__->meta->make_immutable;
};

package DeviceMaster::AppUtils::Packet::Set {
	use namespace::autoclean;
	use Moo;

	use Types::Standard ();

	use DeviceMaster::AppUtils::Packet;

	with 'DeviceMaster::AppUtils::Packet';

	has '+type' => (
		init_arg => undef,
		default => sub { 'Set' }
	);

	has path => (
		is => 'ro',
		isa => Types::Standard::Str,
		required => 1
	);

	has value => (
		is => 'ro',
		isa => Types::Standard::Str,
		required => 1
	);

	__PACKAGE__->meta->make_immutable;
};

1;

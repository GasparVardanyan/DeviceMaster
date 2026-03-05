use strict;
use warnings;

package DeviceMaster::Utils::Serializable {
	use namespace::autoclean;
	use Moo::Role;
	use Moo::Role::ToJSON;

	use Types::Standard ();

	with 'Moo::Role::ToJSON';

	requires '_serializable_attributes';

	has __CLASS__ => (
		is => 'ro',
		isa => Types::Standard::Str,
		init_arg => undef,
		default => sub {
			my $self = shift;
			ref $self;
		}
	);

	sub _build_serializable_attributes {
		my $self = shift;
		my $attrs = $self->_serializable_attributes;
		unshift @$attrs, '__CLASS__';
		return $attrs;
	}
}

1;

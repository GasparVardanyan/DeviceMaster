use strict;
use warnings;

package DeviceMaster::Utils::Serializable {
	use namespace::autoclean;
	use Moo::Role;

	requires 'serializable_attributes';

	sub TO_JSON {
		my $self = shift;

		return {
			'__CLASS__' => ref $self,
			map { $_ => $self->$_ } @{ $self->serializable_attributes }
		};
	}
}

1;

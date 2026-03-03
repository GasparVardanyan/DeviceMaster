use strict;
use warnings;

package DeviceMaster::Utils::Serializable {
	use namespace::autoclean;
	use Moo::Role;
	use Moo::Role::ToJSON;

	with 'Moo::Role::ToJSON';

	# use MooseX::Storage;
	#
	# with Storage ( 'format' => 'JSON' );
}

1;

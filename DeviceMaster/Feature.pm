use strict;
use warnings;

package DeviceMaster::Feature {
	use namespace::autoclean;
	use Moo::Role;
	use Types::Standard ();

	has name => ( is => 'ro', isa => Types::Standard::Str, required => 1 );

	requires 'supports';
	requires 'make_interface';
}

1;

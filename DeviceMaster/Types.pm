use strict;
use warnings;

package DeviceMaster::Types {
	use namespace::autoclean;
	use Moose::Util::TypeConstraints;

	use List::Util ();
	use POSIX ();

	subtype 'DeviceMaster::Types::Percentage'
		=> as 'Num'
		=> where { $_ >= 0 && $_ <= 100 }
		=> message { 'invalid percentage' }
	;

	sub MakePercentage {
		my $p = shift;
		if ($p < 0) {
			$p = 0;
		}
		elsif ($p > 100) {
			$p = 100;
		}

		return $p;
	}

	sub BoundInt {
		my $real = shift;
		my $lower = shift;
		my $upper = shift;

		return List::Util::min ($upper, List::Util::max ($lower, POSIX::lrint $real));
	}
}

1;

use strict;
use warnings;

package DeviceMaster::Types {
	use namespace::autoclean;

	use base 'Type::Library';
	use Types::Standard ();
	use Type::Utils ();

	use List::Util ();
	use POSIX ();

	Type::Utils::declare 'Percentage',
		Type::Utils::as Types::Standard::Num,
		Type::Utils::where { $_ >= 0 && $_ <= 100 },
		Type::Utils::message { 'invalid percentage' }
	;

	# Type::Utils::coerce 'Percentage',
	# Type::Utils::from Types::Standard::Num,
	# Type::Utils::via {
	# 	$_ < 0   ? 0
	#   : $_ > 100 ? 100
	#   : $_;
	# };

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

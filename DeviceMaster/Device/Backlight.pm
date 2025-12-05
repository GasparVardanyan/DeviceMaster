use strict;
use warnings;

=begin comment

	https://www.kernel.org/doc/html/latest/gpu/backlight.html

=end comment

=cut

package DeviceMaster::Device::Backlight {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::Feature;

	my %_Features = map { $_ => DeviceMaster::FeatureFile->new (
		name => $_
	) } qw (
		brightness
		actual_brightness
		max_brightness
	);

	with 'DeviceMaster::Device';

	has '+Features' => (
		default => sub { \%_Features }
	);
}

1;

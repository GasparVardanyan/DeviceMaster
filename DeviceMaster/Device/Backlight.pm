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
	use DeviceMaster::Virtual::FeatureVirtualInterfaces;

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

	has '+feature_interfaces_virtual' => (
		default => sub {
			my $self = shift;

			return {
				brightness_pct => DeviceMaster::Virtual::FeaturePercentageInterface->new (
					lower_bound => \$DeviceMaster::Virtual::FeatureConstantInterface::Zero,
					upper_bound => \$self->feature_interfaces->{max_brightness},
					target => \$self->feature_interfaces->{brightness}
				)
			};
		}
	);
}

1;

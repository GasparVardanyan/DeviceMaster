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

	my %_FeaturesVirtual = map {
		my ($upper_bound, $target) = @{$_};

		my $name = $target . '_pct';

		$name => DeviceMaster::Virtual::FeatureVirtual->new (
			name => $name,
			dependencies => [$upper_bound, $target],
			generate => sub {
				my $device = shift;

				return DeviceMaster::Virtual::FeaturePercentageInterface->new (
					lower_bound => \$DeviceMaster::Virtual::FeatureConstantInterface::Zero,
					upper_bound => \$device->feature_interfaces->{$upper_bound},
					target => \$device->feature_interfaces->{$target}
				);
			}
		)
	} (
		[ 'max_brightness', 'brightness' ],
		[ 'max_brightness', 'actual_brightness' ]
	);
	with 'DeviceMaster::Device';

	has '+Features' => (
		default => sub { \%_Features }
	);

	has '+FeaturesVirtual' => (
		default => sub { \%_FeaturesVirtual }
	);
}

1;

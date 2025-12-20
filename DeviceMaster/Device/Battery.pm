use strict;
use warnings;

=begin comment

	https://www.kernel.org/doc/html/latest/power/power_supply_class.html

=end comment

=cut

package DeviceMaster::Device::Battery {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::Feature;

	my %_Features = map { $_ => DeviceMaster::FeatureFile->new (
		name => $_
	) } qw (
		status
		capacity
		technology
		model_name
		charge_control_start_threshold
		charge_control_end_threshold
	);


	my %_FeaturesVirtual = map {
		my $target = $_;

		my $name = $target . '_pct';

		$name => DeviceMaster::Virtual::FeatureVirtual->new (
			name => $name,
			dependencies => [$target],
			generate => sub {
				my $device = shift;

				return DeviceMaster::Virtual::FeaturePercentageInterface->new (
					lower_bound => \$DeviceMaster::Virtual::FeatureConstantInterface::Zero,
					upper_bound => \$DeviceMaster::Virtual::FeatureConstantInterface::Hundred,
					target => \$device->feature_interfaces->{$target}
				);
			}
		)
	} qw (
		charge_control_start_threshold
		charge_control_end_threshold
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

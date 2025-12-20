use strict;
use warnings;

=begin comment

	https://docs.kernel.org/userspace-api/sysfs-platform_profile.html

=end comment

=cut

package DeviceMaster::Device::PlatformProfile {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::Feature;

	my %_Features = map { $_ => DeviceMaster::FeatureFile->new (
		name => $_
	) } qw (
		name
		profile
		choices
	);

	my %_FeaturesVirtual = (
		profile => DeviceMaster::Virtual::FeatureVirtual->new (
			name => 'profile',
			dependencies => ['choices', 'profile'],
			generate => sub {
				my $device = shift;

				return DeviceMaster::Virtual::FeatureChoiceInterface->new (
					choices => \$device->feature_interfaces->{choices},
					target => \$device->feature_interfaces->{profile}
				);
			}
		)
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

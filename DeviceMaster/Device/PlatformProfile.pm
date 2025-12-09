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

	with 'DeviceMaster::Device';

	has '+Features' => (
		default => sub { \%_Features }
	);

	has '+feature_interfaces_virtual' => (
		default => sub {
			my $self = shift;

			return {
				profile => DeviceMaster::Virtual::FeatureChoiceInterface->new (
					choices => \$self->feature_interfaces->{choices},
					target => \$self->feature_interfaces->{profile}
				)
			};
		}
	);
}

1;

use strict;
use warnings;

=begin comment

	https://docs.kernel.org/hwmon/sysfs-interface.html

=end comment

=cut

package DeviceMaster::Device::HwMon {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::Feature;

	use File::Basename;

	my @_FeaturesGlobs = qw (
		curr*_input
		fan*_boost
		fan*_input
		fan*_label
		fan*_max
		fan*_min
		fan*_target
		in*_input
		name
		pwm*
		pwm*_auto_channels_temp
		temp*_alarm
		temp*_crit
		temp*_crit_alarm
		temp*_enable
		temp*_input
		temp*_label
		temp*_lcrit
		temp*_lcrit_alarm
		temp*_max
		temp*_max_alarm
		temp*_min
		temp*_min_alarm
	);

	with 'DeviceMaster::Device';

	has '+Features' => (
		default => sub {
			my $self = shift;
			my $dir = $self->dir;

			return {
				map {
					$_->name => $_
				} map {
					DeviceMaster::FeatureFile->new (
						name => File::Basename::basename $_
					)
				} map { glob $dir . $_ } @_FeaturesGlobs
			};
		},
		lazy => 1
	);
}

1;

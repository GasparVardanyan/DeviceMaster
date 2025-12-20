use strict;
use warnings;

package DeviceMaster::Device::GPU::I915 {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::Feature;

	use List::Util ();

	my @_FeaturesGlobs = qw (
		gt_boost_freq_mhz
		gt_max_freq_mhz
		gt_min_freq_mhz
		gt_RP0_freq_mhz
		gt_RP1_freq_mhz
		gt_RPn_freq_mhz
		gt_*_freq_mhz
	);

	my %_FeaturesVirtual = map {
		my ($lower_bound, $upper_bound, $target) = @{$_};

		my $name = $target . '_pct';

		$name => DeviceMaster::Virtual::FeatureVirtual->new (
			name => $name,
			dependencies => [$lower_bound, $upper_bound, $target],
			generate => sub {
				my $device = shift;

				return DeviceMaster::Virtual::FeaturePercentageInterface->new (
					lower_bound => \$device->feature_interfaces->{$lower_bound},
					upper_bound => \$device->feature_interfaces->{$upper_bound},
					target => \$device->feature_interfaces->{$target}
				);
			}
		)
	} (
		[ 'gt_RPn_freq_mhz', 'gt_RP0_freq_mhz', 'gt_min_freq_mhz' ],
		[ 'gt_RPn_freq_mhz', 'gt_RP0_freq_mhz', 'gt_max_freq_mhz' ],
		[ 'gt_RPn_freq_mhz', 'gt_RP0_freq_mhz', 'gt_boost_freq_mhz' ]
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
				} List::Util::uniq map { glob $dir . $_ } @_FeaturesGlobs
			};
		},
		lazy => 1
	);

	has '+FeaturesVirtual' => (
		default => sub { \%_FeaturesVirtual }
	);

	has driver => ( is => 'ro', isa => 'Str', required => 1 );
}

1;

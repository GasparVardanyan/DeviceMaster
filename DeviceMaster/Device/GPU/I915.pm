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

	has '+feature_interfaces_virtual' => (
		default => sub {
			my $self = shift;

			return {
				gt_min_freq_mhz_pct => DeviceMaster::Virtual::FeaturePercentageInterface->new (
					lower_bound => \$self->feature_interfaces->{gt_RPn_freq_mhz},
					upper_bound => \$self->feature_interfaces->{gt_RP0_freq_mhz},
					target => \$self->feature_interfaces->{gt_min_freq_mhz}
				),
				gt_max_freq_mhz_pct => DeviceMaster::Virtual::FeaturePercentageInterface->new (
					lower_bound => \$self->feature_interfaces->{gt_RPn_freq_mhz},
					upper_bound => \$self->feature_interfaces->{gt_RP0_freq_mhz},
					target => \$self->feature_interfaces->{gt_max_freq_mhz}
				),
				gt_boost_freq_mhz_pct => DeviceMaster::Virtual::FeaturePercentageInterface->new (
					lower_bound => \$self->feature_interfaces->{gt_RPn_freq_mhz},
					upper_bound => \$self->feature_interfaces->{gt_RP0_freq_mhz},
					target => \$self->feature_interfaces->{gt_boost_freq_mhz}
				),
			};
		}
	);

	has driver => ( is => 'ro', isa => 'Str', required => 1 );
}

1;

use strict;
use warnings;

package DeviceMaster::Device::GPU::I915 {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::Feature;

	my @_FeaturesGlobs = qw (
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
				} map { glob $dir . $_ } @_FeaturesGlobs
			};
		},
		lazy => 1
	);

	has driver => ( is => 'ro', isa => 'Str', required => 1 );
}

1;

use strict;
use warnings;

=begin comment

	https://www.kernel.org/doc/html/next/power/powercap/powercap.html

=end comment

=cut

package DeviceMaster::Device::CPU::IntelRapl {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::Feature;

	use File::Basename;

	my @_FeaturesGlobs = qw (
		constraint_*_max_power_uw
		constraint_*_name
		constraint_*_power_limit_uw
		constraint_*_time_window_us
		enabled
		energy_uj
		max_energy_range_uj
		name
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

	has subzones => (
		is => 'ro',
		isa => 'HashRef[DeviceMaster::Device::CPU::IntelRapl]',
		default => sub {
			my $self = shift;

			my $dir = $self->dir;

			return {
				map {
					$_->id => $_
				} map {
					DeviceMaster::Device::CPU::IntelRapl->new (
						dir => $_,
						id => $_ =~ s/^\Q$dir\E//r =~ s/\/$//r
					)
				} glob ($dir . 'intel-rapl*/')
			};
		},
		lazy => 1
	);

	sub BUILD {
		my $self = shift;

		$self->subzones;
	}
}

1;

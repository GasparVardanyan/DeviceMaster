use strict;
use warnings;

=begin comment

	https://docs.kernel.org/admin-guide/pm/intel_pstate.html
	https://docs.kernel.org/admin-guide/pm/cpufreq.html

=end comment

=cut

package DeviceMaster::Device::CPU::IntelPState {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::Feature;
	use DeviceMaster::Virtual::FeatureVirtualInterfaces;

	use List::Util ();

	my %_Features = map { $_ => DeviceMaster::FeatureFile->new (
		name => $_,
		path_func => sub {
			my $device = shift;
			my $feature = shift;

			return $device->dir . 'intel_pstate/' . $feature->name;
		}
	) } qw (
		hwp_dynamic_boost
		max_perf_pct
		min_perf_pct
		no_turbo
		status
	);

	with 'DeviceMaster::Device';

	has '+Features' => (
		default => sub { \%_Features }
	);

	our $FeatureStatusChoice = DeviceMaster::Virtual::FeatureConstantInterface->new (
		value => join ' ', qw (
			active
			passive
			off
		)
	);

	has '+feature_interfaces_virtual' => (
		default => sub {
			my $self = shift;

			return {
				status => DeviceMaster::Virtual::FeatureChoiceInterface->new (
					choices => \$DeviceMaster::Device::CPU::IntelPState::FeatureStatusChoice,
					target => \$self->feature_interfaces->{status}
				),
				scaling_governor => DeviceMaster::Virtual::FeatureCompoundInterface->new (
					targets => {
						map {
							$_ => \$self->scaling_policies->{$_}->feature_interfaces_virtual->{scaling_governor}
						} keys %{ $self->scaling_policies }
					}
				),
				energy_performance_preference => DeviceMaster::Virtual::FeatureCompoundInterface->new (
					targets => {
						map {
							$_ => \$self->scaling_policies->{$_}->feature_interfaces_virtual->{energy_performance_preference}
						} keys %{ $self->scaling_policies }
					}
				),
				scaling_min_freq_pct => DeviceMaster::Virtual::FeatureCompoundInterface->new (
					targets => {
						map {
							$_ => \$self->scaling_policies->{$_}->feature_interfaces_virtual->{scaling_min_freq_pct}
						} keys %{ $self->scaling_policies }
					}
				),
				scaling_max_freq_pct => DeviceMaster::Virtual::FeatureCompoundInterface->new (
					targets => {
						map {
							$_ => \$self->scaling_policies->{$_}->feature_interfaces_virtual->{scaling_max_freq_pct}
						} keys %{ $self->scaling_policies }
					}
				),
			};
		}
	);

	has scaling_policies => (
		is => 'ro',
		isa => 'HashRef[DeviceMaster::Device::CPU::IntelPState::CpuFreqPolicy]',
		default => sub {
			my $self = shift;

			my $dir = $self->dir;

			return {
				map {
					$_->id => $_
				} map {
					DeviceMaster::Device::CPU::IntelPState::CpuFreqPolicy->new (
						dir => $_,
						id => $_ =~ s/^\Q$dir\E//r =~ s/\/$//r =~ s/\//_/r
					)
				} List::Util::uniq glob ($dir . 'cpufreq/policy*/')
			};
		},
		lazy => 1
	);

	sub BUILD {
		my $self = shift;
		$self->scaling_policies;
	}
}

package DeviceMaster::Device::CPU::IntelPState::CpuFreqPolicy {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::Feature;

	my %_Features = map { $_ => DeviceMaster::FeatureFile->new (
		name => $_
	) } qw (
		affected_cpus
		base_frequency
		cpuinfo_avg_freq
		cpuinfo_max_freq
		cpuinfo_min_freq
		energy_performance_available_preferences
		energy_performance_preference
		scaling_available_governors
		scaling_governor
		scaling_max_freq
		scaling_min_freq
		scaling_setspeed
	);

	with 'DeviceMaster::Device';

	has '+Features' => (
		default => sub { \%_Features }
	);

	has '+feature_interfaces_virtual' => (
		default => sub {
			my $self = shift;

			return {
				scaling_min_freq_pct => DeviceMaster::Virtual::FeaturePercentageInterface->new (
					lower_bound => \$self->feature_interfaces->{cpuinfo_min_freq},
					upper_bound => \$self->feature_interfaces->{cpuinfo_max_freq},
					target => \$self->feature_interfaces->{scaling_min_freq}
				),
				scaling_max_freq_pct => DeviceMaster::Virtual::FeaturePercentageInterface->new (
					lower_bound => \$self->feature_interfaces->{cpuinfo_min_freq},
					upper_bound => \$self->feature_interfaces->{cpuinfo_max_freq},
					target => \$self->feature_interfaces->{scaling_max_freq}
				),
				scaling_governor => DeviceMaster::Virtual::FeatureChoiceInterface->new (
					choices => \$self->feature_interfaces->{scaling_available_governors},
					target => \$self->feature_interfaces->{scaling_governor}
				),
				energy_performance_preference => DeviceMaster::Virtual::FeatureChoiceInterface->new (
					choices => \$self->feature_interfaces->{energy_performance_available_preferences},
					target => \$self->feature_interfaces->{energy_performance_preference}
				),
			};
		}
	);

}

1;

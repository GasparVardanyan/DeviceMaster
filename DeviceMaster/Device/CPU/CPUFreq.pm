use strict;
use warnings;

=begin comment

	https://docs.kernel.org/admin-guide/pm/cpufreq.html

=end comment

=cut

package DeviceMaster::Device::CPU::CPUFreq {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::Feature;
	use DeviceMaster::Virtual::FeatureVirtualInterfaces;

	use List::Util ();

	my %_FeaturesVirtual = map {
		my $compound_name = $_;

		$compound_name => DeviceMaster::Virtual::FeatureVirtual->new (
			name => $compound_name,
			dependencies => [$compound_name],
			dependency_resolver => sub {
				my $device = shift;
				my $feature = shift;

				return DeviceMaster::Virtual::FeatureVirtual::DependencyResolver::CompoundDependencies (
					$device, $feature, $device->policies, 'feature_interfaces_virtual'
				);
			},
			generate => sub {
				my $device = shift;

				return DeviceMaster::Virtual::FeatureCompoundInterface->new (
					targets => {
						map {
							$_ => \$device->policies->{$_}->feature_interfaces_virtual->{$compound_name}
						} keys %{ $device->policies }
					}
				);
			}
		)
	} qw (
		scaling_governor
		energy_performance_preference
		scaling_min_freq_pct
		scaling_max_freq_pct
	);

	with 'DeviceMaster::Device';

	has '+FeaturesVirtual' => (
		default => sub { \%_FeaturesVirtual }
	);

	has policies => (
		is => 'ro',
		isa => 'HashRef[DeviceMaster::Device::CPU::CPUFreq::Policy]',
		init_arg => undef,
		default => sub {
			my $self = shift;

			my $dir = $self->dir;

			return {
				map {
					$_->id => $_
				} map {
					DeviceMaster::Device::CPU::CPUFreq::Policy->new (
						dir => $_,
						id => $_ =~ s/^\Q$dir\E//r =~ s/\/$//r =~ s/\//_/r
					)
				} List::Util::uniq glob ($dir . 'policy*/')
			};
		},
		lazy => 1
	);

	before BUILD => sub {
		my $self = shift;
		$self->policies;
	};

	sub BUILD { }
}

package DeviceMaster::Device::CPU::CPUFreq::Policy {
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

	my %_FeaturesVirtual = (
		scaling_min_freq_pct => DeviceMaster::Virtual::FeatureVirtual->new (
			name => 'scaling_min_freq_pct',
			dependencies => [qw (
				cpuinfo_min_freq
				cpuinfo_max_freq
				scaling_min_freq
			)],
			generate => sub {
				my $device = shift;

				return DeviceMaster::Virtual::FeaturePercentageInterface->new (
					lower_bound => \$device->feature_interfaces->{cpuinfo_min_freq},
					upper_bound => \$device->feature_interfaces->{cpuinfo_max_freq},
					target => \$device->feature_interfaces->{scaling_min_freq}
				);
			}
		),
		scaling_max_freq_pct => DeviceMaster::Virtual::FeatureVirtual->new (
			name => 'scaling_max_freq_pct',
			dependencies => [qw (
				cpuinfo_min_freq
				cpuinfo_max_freq
				scaling_max_freq
			)],
			generate => sub {
				my $device = shift;

				return DeviceMaster::Virtual::FeaturePercentageInterface->new (
					lower_bound => \$device->feature_interfaces->{cpuinfo_min_freq},
					upper_bound => \$device->feature_interfaces->{cpuinfo_max_freq},
					target => \$device->feature_interfaces->{scaling_max_freq}
				);
			}
		),
		scaling_governor => DeviceMaster::Virtual::FeatureVirtual->new (
			name => 'scaling_governor',
			dependencies => ['scaling_governor', 'scaling_available_governors'],
			generate => sub {
				my $device = shift;

				return DeviceMaster::Virtual::FeatureChoiceInterface->new (
					choices => \$device->feature_interfaces->{scaling_available_governors},
					target => \$device->feature_interfaces->{scaling_governor}
				);
			}
		),
		energy_performance_preference => DeviceMaster::Virtual::FeatureVirtual->new (
			name => 'energy_performance_preference',
			dependencies => ['energy_performance_preference', 'energy_performance_available_preferences'],
			generate => sub {
				my $device = shift;

				return DeviceMaster::Virtual::FeatureChoiceInterface->new (
					choices => \$device->feature_interfaces->{energy_performance_available_preferences},
					target => \$device->feature_interfaces->{energy_performance_preference}
				);
			}
		),
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

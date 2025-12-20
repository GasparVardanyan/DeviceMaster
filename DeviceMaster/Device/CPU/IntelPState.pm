use strict;
use warnings;

=begin comment

	https://docs.kernel.org/admin-guide/pm/intel_pstate.html

=end comment

=cut

package DeviceMaster::Device::CPU::IntelPState {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::Feature;
	use DeviceMaster::Virtual::FeatureVirtualInterfaces;

	use List::Util ();

	my %_Features = map { $_ => DeviceMaster::FeatureFile->new (
		name => $_
	) } qw (
		hwp_dynamic_boost
		max_perf_pct
		min_perf_pct
		no_turbo
		status
	);

	my %_FeaturesVirtual = (
		status => DeviceMaster::Virtual::FeatureVirtual->new (
			name => 'status',
			dependencies => ['status'],
			generate => sub {
				my $device = shift;

				return DeviceMaster::Virtual::FeatureChoiceInterface->new (
					choices => \$DeviceMaster::Device::CPU::IntelPState::FeatureStatusChoice,
					target => \$device->feature_interfaces->{status}
				);
			}
		),
		no_turbo => DeviceMaster::Virtual::FeatureVirtual->new (
			name => 'no_turbo',
			dependencies => ['no_turbo'],
			generate => sub {
				my $device = shift;

				return DeviceMaster::Virtual::FeatureChoiceInterface->new (
					choices => \$DeviceMaster::Virtual::FeatureChoiceInterface::Boolean,
					target => \$device->feature_interfaces->{no_turbo}
				);
			}
		),
		hwp_dynamic_boost => DeviceMaster::Virtual::FeatureVirtual->new (
			name => 'hwp_dynamic_boost',
			dependencies => ['hwp_dynamic_boost'],
			generate => sub {
				my $device = shift;

				return DeviceMaster::Virtual::FeatureChoiceInterface->new (
					choices => \$DeviceMaster::Virtual::FeatureChoiceInterface::Boolean,
					target => \$device->feature_interfaces->{hwp_dynamic_boost}
				);
			}
		),
		max_perf_pct => DeviceMaster::Virtual::FeatureVirtual->new (
			name => 'max_perf_pct',
			dependencies => ['max_perf_pct'],
			generate => sub {
				my $device = shift;

				return DeviceMaster::Virtual::FeaturePercentageInterface->new (
					lower_bound => \$DeviceMaster::Virtual::FeatureConstantInterface::Zero,
					upper_bound => \$DeviceMaster::Virtual::FeatureConstantInterface::Hundred,
					target => \$device->feature_interfaces->{max_perf_pct}
				);
			}
		),
		min_perf_pct => DeviceMaster::Virtual::FeatureVirtual->new (
			name => 'min_perf_pct',
			dependencies => ['min_perf_pct'],
			generate => sub {
				my $device = shift;

				return DeviceMaster::Virtual::FeaturePercentageInterface->new (
					lower_bound => \$DeviceMaster::Virtual::FeatureConstantInterface::Zero,
					upper_bound => \$DeviceMaster::Virtual::FeatureConstantInterface::Hundred,
					target => \$device->feature_interfaces->{min_perf_pct}
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

	our $FeatureStatusChoice = DeviceMaster::Virtual::FeatureConstantInterface->new (
		value => join ' ', qw (
			active
			passive
			off
		)
	);
}

1;

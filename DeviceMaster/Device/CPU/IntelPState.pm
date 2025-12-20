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
				no_turbo => DeviceMaster::Virtual::FeatureChoiceInterface->new (
					choices => \$DeviceMaster::Virtual::FeatureChoiceInterface::Boolean,
					target => \$self->feature_interfaces->{no_turbo}
				),
				hwp_dynamic_boost => DeviceMaster::Virtual::FeatureChoiceInterface->new (
					choices => \$DeviceMaster::Virtual::FeatureChoiceInterface::Boolean,
					target => \$self->feature_interfaces->{hwp_dynamic_boost}
				),
				max_perf_pct => DeviceMaster::Virtual::FeaturePercentageInterface->new (
					lower_bound => \$DeviceMaster::Virtual::FeatureConstantInterface::Zero,
					upper_bound => \$DeviceMaster::Virtual::FeatureConstantInterface::Hundred,
					target => \$self->feature_interfaces->{max_perf_pct}
				),
				min_perf_pct => DeviceMaster::Virtual::FeaturePercentageInterface->new (
					lower_bound => \$DeviceMaster::Virtual::FeatureConstantInterface::Zero,
					upper_bound => \$DeviceMaster::Virtual::FeatureConstantInterface::Hundred,
					target => \$self->feature_interfaces->{min_perf_pct}
				)
			};
		}
	);
}

1;

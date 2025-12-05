use strict;
use warnings;

=begin comment

	https://www.kernel.org/doc/html/latest/power/power_supply_class.html

=end comment

=cut

package DeviceMaster::Device::Battery {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::Feature;

	my %_Features = map { $_ => DeviceMaster::FeatureFile->new (
		name => $_
	) } qw (
		status
		capacity
		technology
		model_name
		charge_control_start_threshold
		charge_control_end_threshold
	);

	with 'DeviceMaster::Device';

	has '+Features' => (
		default => sub { \%_Features }
	);
}

1;

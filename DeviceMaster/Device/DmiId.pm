use strict;
use warnings;

package DeviceMaster::Device::DmiId {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::Feature;

	my %_Features = map { $_ => DeviceMaster::FeatureFile->new (
		name => $_
	) } qw (
		bios_date
		bios_release
		bios_vendor
		bios_version
		board_name
		board_vendor
		board_version
		product_family
		product_name
		product_sku
		sys_vendor
	);

	with 'DeviceMaster::Device';

	has '+Features' => (
		default => sub { \%_Features }
	);
}

1;

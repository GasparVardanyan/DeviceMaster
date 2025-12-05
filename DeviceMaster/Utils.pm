use strict;
use warnings;

package DeviceMaster::Utils {
	sub read_sys_file {
		my ($filepath) = @_;

		open (my $fh, '<', $filepath) or return "Error opening file $filepath.";

		my $value = <$fh>;
		close $fh;

		chomp $value if defined $value;

		return $value;
	}

	sub write_sys_file {
		my ($filepath, $value) = @_;

		$value = '' unless defined $value;

		open (my $fh, '>', $filepath) or return "Error opening file $filepath for writing: $!";

		print $fh "$value\n";

		close $fh;

		return 1;
	}
}

package DeviceMaster::Utils::Serializable {
	use namespace::autoclean;
	use Moose::Role;

	use MooseX::Storage;

	with Storage ( 'format' => 'JSON' );
}

1;

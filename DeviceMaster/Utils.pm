use strict;
use warnings;

package DeviceMaster::Utils {
	use Fcntl;

	use POSIX qw(sysconf _SC_PAGESIZE);

	my $PAGESIZE = sysconf(_SC_PAGESIZE) || 4096;

	sub read_sys_file {
		my ($path) = @_;

		sysopen (my $fh, $path, Fcntl::O_RDONLY) or return undef;

		my $buf = '';
		sysread ($fh, $buf, $PAGESIZE);
		close $fh;

		$buf =~ s/\n\z//;
		return $buf;
	}

	sub write_sys_file {
		my ($path, $value) = @_;
		$value //= '';

		sysopen (my $fh, $path, Fcntl::O_WRONLY | Fcntl::O_TRUNC) or return undef;
		syswrite ($fh, "$value\n");
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

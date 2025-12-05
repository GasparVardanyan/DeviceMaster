use strict;
use warnings;

=begin comment

	https://docs.kernel.org/userspace-api/sysfs-platform_profile.html

=end comment

=cut

package DeviceMaster::Device::PlatformProfile {
	use namespace::autoclean;
	use Moose;

	use DeviceMaster::Feature;

	my %_Features = map { $_ => DeviceMaster::FeatureFile->new (
		name => $_
	) } qw (
		name
		profile
		choices
	);

	with 'DeviceMaster::Device';

	has '+Features' => (
		default => sub { \%_Features }
	);

	has choices => (
		is => 'ro',
		isa => 'ArrayRef[Str]',
		traits => ['DoNotSerialize'],
		default => sub {
			my $self = shift;

			return [ split ' ', $self->acquire ('choices') ];
		},
		lazy => 1
	);

	sub BUILD {
		my $self = shift;
		$self->choices;
	}

	sub set_profile {
		my $self = shift;
		my $profile = shift;

		if (grep { $_ eq $profile } @{ $self->choices }) {
			$self->set ('profile', $profile);
		}
	}
}

1;

use strict;
use warnings;

package DeviceMaster::DeviceSystem {
	use namespace::autoclean;
	use Moo;
	# use Moose::Util::TypeConstraints;

	use DeviceMaster::Utils::Serializable;

	use Cwd ();

	use Data::Dumper ();
	use Data::Diver ();
	use File::Basename ();

	# enum DeviceType => [ 'Alienware', 'Generic' ];

	use DeviceMaster::Utils;
	use DeviceMaster::Device::Backlight;
	use DeviceMaster::Device::Battery;
	use DeviceMaster::Device::DmiId;
	use DeviceMaster::Device::PlatformProfile;
	use DeviceMaster::Device::CPU::CPUFreq;
	use DeviceMaster::Device::CPU::IntelPState;
	use DeviceMaster::Device::CPU::IntelRapl;
	use DeviceMaster::Device::GPU::I915;
	use DeviceMaster::Device::HwMon;

	has device_type => (
		is => 'ro',
		# isa => 'DeviceType',
		init_arg => undef
	);

	has dmi_id => (
		is => 'ro',
		isa => Types::Standard::InstanceOf['DeviceMaster::Device::DmiId'],
		init_arg => undef,
		default => sub { DeviceMaster::Device::DmiId->new (
			dir => '/sys/class/dmi/id/',
			id => 'dmi_id'
		) }
	);

	has batteries => (
		is => 'ro',
		isa => Types::Standard::HashRef[Types::Standard::InstanceOf['DeviceMaster::Device::Battery']],
		init_arg => undef,
		default => sub { {} }
	);
	has backlights => (
		is => 'ro',
		isa => Types::Standard::HashRef[Types::Standard::InstanceOf['DeviceMaster::Device::Backlight']],
		init_arg => undef,
		default => sub { {} }
	);
	has platform_profiles => (
		is => 'ro',
		isa => Types::Standard::HashRef[Types::Standard::InstanceOf['DeviceMaster::Device::PlatformProfile']],
		init_arg => undef,
		default => sub { {} }
	);
	has cpu => (
		is => 'ro',
		isa => Types::Standard::HashRef[Types::Standard::ConsumerOf['DeviceMaster::Device']],
		init_arg => undef,
		default => sub { {} }
	);
	has gpu => (
		is => 'ro',
		isa => Types::Standard::HashRef[Types::Standard::ConsumerOf['DeviceMaster::Device']],
		init_arg => undef,
		default => sub { {} }
	);
	has hwmons => (
		is => 'ro',
		isa => Types::Standard::HashRef[Types::Standard::InstanceOf['DeviceMaster::Device::HwMon']],
		init_arg => undef,
		default => sub { {} }
	);

	sub _serializable_attributes { [qw(
		dmi_id
		batteries
		backlights
		platform_profiles
		cpu
		gpu
		hwmons
	)]; }
	with 'DeviceMaster::Utils::Serializable';

	sub BUILD {
		my $self = shift;

		$self->_identify_devicetype;

		$self->_initialize_cpu;
		$self->_initialize_gpus;
		$self->_initialize_platform_profiles;
		$self->_initialize_hwmons;
		$self->_initialize_batteries;
		$self->_initialize_backlights;
	}

	sub dive {
		my $self = shift;
		my $path = shift;

		if ('/' eq $path) {
			return \$self;
		}
		elsif ($path =~ s/^\///) {
			return Data::Diver::DiveRef ($self, split '/', $path);
		}
		else {
			return undef;
		}
	}

	sub _identify_devicetype {
		my $self = shift;

		if (
			$self->dmi_id->acquire ('product_family') eq 'GSeries' # FIXME: Probably Alienware devices have another 'family'
			&& ($self->dmi_id->acquire ('product_name') =~ /(?:^(?:Dell|Alienware))|(?:^G3 3590$)|(?:^G5 5590$)|(?:^G7 7500$)|(?:^G7 7700$)/)
			# https://github.com/tr1xem/AWCC/blob/cb05cb8da2831fcc85223b2a5ce1e430b46da01d/database.json
		) {
			$self->{device_type} = 'Alienware';
		}
		else {
			$self->{device_type} = 'Generic';
		}
	}

	sub _initialize_cpu {
		my $self = shift;

		if (-d '/sys/devices/system/cpu/cpufreq/') {
			$self->cpu->{'cpufreq'} = DeviceMaster::Device::CPU::CPUFreq->new (
				dir => '/sys/devices/system/cpu/cpufreq/',
				id => 'cpufreq'
			);
		}

		if (-d '/sys/devices/system/cpu/intel_pstate/') {
			$self->cpu->{'intel_pstate'} = DeviceMaster::Device::CPU::IntelPState->new (
				dir => '/sys/devices/system/cpu/intel_pstate/',
				id => 'intel_pstate'
			);
		}

		if (-d '/sys/class/powercap/intel-rapl/') {
			$self->cpu->{'intel-rapl'} = DeviceMaster::Device::CPU::IntelRapl->new (
				dir => '/sys/class/powercap/intel-rapl/',
				id => 'intel-rapl'
			);
		}
	}

	sub _initialize_gpus {
		my $self = shift;

		for my $card_dir (glob '/sys/class/drm/card*/') {
			if ($card_dir =~ qr/card(\d+)\/?$/) {
				my $card                         =   'card' . $1;
				my $card_driver_symlink          =   "$card_dir/device/driver";
				my $card_driver_path             =   Cwd::abs_path ($card_driver_symlink);
				my ($card_driver_name)           =   $card_driver_path =~ qr#\/([^/]+)\/?$#;

				if ('i915' eq $card_driver_name) {
					$self->gpu->{$card} = DeviceMaster::Device::GPU::I915-> new (
						dir => $card_dir,
						id => $card,
						driver => $card_driver_name
					);
				}
			}
		}
	}

	sub _initialize_platform_profiles {
		my $self = shift;

		my $platform_profile_glob = '/sys/class/platform-profile/platform-profile-*/';
		my $platform_profile_matcher = qr#/(platform-profile-\d+)/$#;

		for my $platform_profile (glob $platform_profile_glob) {
			if ($platform_profile =~ $platform_profile_matcher) {
				$self->platform_profiles->{$1} = DeviceMaster::Device::PlatformProfile->new (
					dir => $platform_profile,
					id => $1
				);
			}
		}
	}

	sub _initialize_hwmons {
		my $self = shift;

		my $hwmon_glob = '/sys/class/hwmon/hwmon*/';
		my $hwmon_matcher = qr#/(hwmon\d+)/$#;

		for my $hwmon (glob $hwmon_glob) {
			if ($hwmon =~ $hwmon_matcher) {
				$self->hwmons->{$1} = DeviceMaster::Device::HwMon->new (
					dir => $hwmon,
					id => $1
				);
			}
		}
	}

	sub _initialize_batteries {
		my $self = shift;

		my $battery_glob = '/sys/class/power_supply/*/';

		for my $battery (glob $battery_glob) {
			my $battery_type_file = $battery . 'type';
			if (-f $battery_type_file) {
				if ('Battery' eq DeviceMaster::Utils::read_sys_file $battery_type_file) {
					my $id = File::Basename::basename $battery;
					$self->batteries->{$id} = DeviceMaster::Device::Battery->new (
						dir => $battery,
						id => $id
					);
				}
			}
		}
	}

	sub _initialize_backlights {
		my $self = shift;

		my $backlight_glob = '/sys/class/backlight/*/';
		my $backlight_matcher = qr#backlight/(\w+)/$#;

		for my $backlight (glob $backlight_glob) {
			if ($backlight =~ $backlight_matcher) {
				$self->backlights->{$1} = DeviceMaster::Device::Backlight->new (
					dir => $backlight,
					id => $1
				);
			}
		}
	}

	__PACKAGE__->meta->make_immutable;
}

1;

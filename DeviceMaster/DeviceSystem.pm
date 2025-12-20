use strict;
use warnings;

package DeviceMaster::DeviceSystem {
	use namespace::autoclean;
	use Moose;
	use Moose::Util::TypeConstraints;

	with 'DeviceMaster::Utils::Serializable';

	use Cwd ();

	use Data::Dumper ();
	use Data::Diver ();
	use File::Basename ();

	enum DeviceType => [ 'Alienware', 'Generic' ];

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
		isa => 'DeviceType',
		init_arg => undef
	);

	has dmi_id => (
		is => 'ro',
		isa => 'DeviceMaster::Device::DmiId',
		init_arg => undef,
		default => sub { DeviceMaster::Device::DmiId->new (
			dir => '/sys/class/dmi/id/',
			id => 'dmi_id'
		) }
	);

	has batteries => (
		is => 'ro',
		isa => 'HashRef[DeviceMaster::Device::Battery]',
		init_arg => undef,
		default => sub { {} }
	);
	has backlights => (
		is => 'ro',
		isa => 'HashRef[DeviceMaster::Device::Backlight]',
		init_arg => undef,
		default => sub { {} }
	);
	has platform_profiles => (
		is => 'ro',
		isa => 'HashRef[DeviceMaster::Device::PlatformProfile]',
		init_arg => undef,
		default => sub { {} }
	);
	has cpu => (
		is => 'ro',
		isa => 'HashRef[DeviceMaster::Device]',
		init_arg => undef,
		default => sub { {} }
	);
	has gpu => (
		is => 'ro',
		isa => 'HashRef[DeviceMaster::Device]',
		init_arg => undef,
		default => sub { {} }
	);
	has hwmons => (
		is => 'ro',
		isa => 'HashRef[DeviceMaster::Device::HwMon]',
		init_arg => undef,
		default => sub { {} }
	);

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

	sub print_info {
		my $self = shift;

		# print Dumper( $self->pack ), "\n";
		# $self->store ("state.json");

		print "dmi_id\n";
		print "id: " . $self->dmi_id->id . "\n";
		$self->print_device_info ($self->dmi_id);

		print "\n" . "-" x 30 . "\n\n";

		print "batteries\n";
		for my $device (values %{ $self->batteries }) {
			print "id: " . $device->id . "\n";
			$self->print_device_info ($device);
		}

		print "\n" . "-" x 30 . "\n\n";

		print "backlights\n";
		for my $device (values %{ $self->backlights }) {
			print "id: " . $device->id . "\n";
			$self->print_device_info ($device);
		}

		print "\n" . "-" x 30 . "\n\n";

		print "platform_profiles\n";
		for my $device (values %{ $self->platform_profiles }) {
			print "id: " . $device->id . "\n";
			$self->print_device_info ($device);
		}

		print "\n" . "-" x 30 . "\n\n";

		print "cpu\n";
		for my $device (values %{ $self->cpu }) {
			print "id: " . $device->id . "\n";
			$self->print_device_info ($device);
			if ($device->isa ('DeviceMaster::Device::CPU::IntelPState')) {
				for my $sp (values %{ $device->scaling_policies }) {
					print "\n" . "-" x 30 . "\n\n";

					print "cpu scaling policy: " . $sp->id . "\n";
					$self->print_device_info ($sp);
				}
			}
		}

		print "\n" . "-" x 30 . "\n\n";

		for my $device (values %{ $self->gpu }) {
			print "id: " . $device->id . "\n";
			$self->print_device_info ($device);
		}
	}

	sub print_device_info {
		my $self = shift;
		my $device = shift;

		my %_F = %{$device->Features};

		for my $feature (sort keys %_F) {
			if ($device->supports ($feature)) {
				my $rw;
				if ($device->readable ($feature)) {
					$rw = "R";
				}
				if ($device->writable ($feature)) {
					$rw = "${rw}W";
				}
				if (1 == length ($rw)) {
					$rw = "${rw}O";
				}

				my $value = $device->acquire ($feature);

				print "feature: [$rw] ${feature} = $value\n";
			}
			else {
				print "unsupported feature: $feature\n";
			}
		}
	}

	sub _identify_devicetype {
		my $self = shift;

		if (
			$self->dmi_id->acquire ('product_family') eq 'GSeries' # FIXME: Probably Alienware devices have another 'family'
			&& ($self->dmi_id->acquire ('product_name') =~ /(?:^(?:Dell|Alienware))|(?:^G7 7500$)/)
			# https://github.com/tr1xem/AWCC/blob/889cc70777c1b416c0707092340f1ac52618d791/database.json
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

				if ("i915" eq $card_driver_name) {
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
}

1;

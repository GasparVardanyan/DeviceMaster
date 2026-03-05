# DeviceMaster
Device manager for computer/laptop parts in Linux.

## Usage
DeviceMaster::Apps::Daemon implements a daemon which takes JSON commands through a UNIX socket.

### Get detected device info
```json
{ "type": "Get", "path": "/" }
```
This will give an output like:
```
{
  "response": {
	"device_type": "Generic",
	"platform_profiles": {
	  "platform-profile-0": {
		"feature_interfaces": {
		  "profile": {
			"writable": "1",
			"__CLASS__": "DeviceMaster::FeatureFileInterface",
			"readable": "1"
		  },
...
  "success": 1
}
```

### Get a specific device info
```json
{ "type": "Get", "path": "/platform_profiles/platform-profile-0" }
```
This will give an output like:
```json
{
  "success": 1,
  "response": {
	"__CLASS__": "DeviceMaster::Device::PlatformProfile",
	"id": "platform-profile-0",
	"feature_interfaces_virtual": {
	  "profile": {
		"__CLASS__": "DeviceMaster::Virtual::FeatureChoiceInterface",
		"readable": "1",
		"writable": "1"
	  }
	},
	"feature_interfaces": {
	  "choices": {
		"__CLASS__": "DeviceMaster::FeatureFileInterface",
		"readable": "1",
		"writable": ""
	  },
	  "name": {
		"__CLASS__": "DeviceMaster::FeatureFileInterface",
		"readable": "1",
		"writable": ""
	  },
	  "profile": {
		"__CLASS__": "DeviceMaster::FeatureFileInterface",
		"readable": "1",
		"writable": "1"
	  }
	}
  }
}
```

### Get a specific feature value of a device
```json
{ "type": "Get", "path": "/platform_profiles/platform-profile-0/feature_interfaces/profile" }
```
This will give an output like:
```json
{
  "response": "quiet",
  "success": 1
}
```

### Set a specific feature of a device to a value
```json
{ "type": "Set", "path": "/backlights/intel_backlight/FI/brightness", "value": "1000" }
```
**FI** is a short for feature_interfaces.
This will change the value, read the updated value from the device and give an output like:
```json
{
  "response": "1000",
  "success": 1
}
```

### Performing multiple commands at once
The current limitation is that the input to the socket must be one line.
**command** is a json object or a json array of objects and arrays.
For example this command:
```json
[
  { "type": "Get", "path": "/gpu/card1/FI/gt_max_freq_mhzXXX_INVALID_PATH" },
  { "type": "Get", "path": "/backlights/intel_backlight/FI/brightness" },
  [
	{ "type": "Get", "path": "/cpu/intel_pstate/FI/hwp_dynamic_boost" },
	{ "type": "Get", "path": "/cpu/intel_pstate/FI/no_turbo" },
	{ "type": "Get", "path": "/cpu/intel_pstate/FI/max_perf_pct" }
  ],
  { "type": "Get", "path": "/cpu/intel_pstate/FI/min_perf_pct" },
  { "type": "Get", "path": "/backlights/intel_backlight" },
  { "type": "Get", "path": "/cpu/intel_pstate/FI/status" },
  { "type": "Set", "path": "/backlights/intel_backlight/FI/brightness", "value": "5000" }
]
```
Combined to one line (**paste -s -d ''**) will give an output like:
```json
[
  {
	"success": 0,
	"error": "invalid data requested",
	"response": ""
  },
  {
	"success": 1,
	"response": "5000"
  },
  [
	{
	  "success": 1,
	  "response": "1"
	},
	{
	  "success": 1,
	  "response": "0"
	},
	{
	  "success": 1,
	  "response": "100"
	}
  ],
  {
	"success": 1,
	"response": "10"
  },
  {
	"success": 1,
	"response": {
	  "__CLASS__": "DeviceMaster::Device::Backlight",
	  "id": "intel_backlight",
	  "feature_interfaces_virtual": {
		"brightness_pct": {
		  "__CLASS__": "DeviceMaster::Virtual::FeaturePercentageInterface",
		  "readable": "1",
		  "writable": "1"
		},
		"actual_brightness_pct": {
		  "__CLASS__": "DeviceMaster::Virtual::FeaturePercentageInterface",
		  "readable": "1",
		  "writable": ""
		}
	  },
	  "feature_interfaces": {
		"max_brightness": {
		  "__CLASS__": "DeviceMaster::FeatureFileInterface",
		  "readable": "1",
		  "writable": ""
		},
		"actual_brightness": {
		  "__CLASS__": "DeviceMaster::FeatureFileInterface",
		  "readable": "1",
		  "writable": ""
		},
		"brightness": {
		  "__CLASS__": "DeviceMaster::FeatureFileInterface",
		  "readable": "1",
		  "writable": "1"
		}
	  }
	}
  },
  {
	"success": 1,
	"response": "active"
  },
  {
	"success": 1,
	"response": "5000"
  }
]
```

### Using Virtual interfaces (choice, percentage and compound wrappers)
```json
[
  { "type": "Set", "path": "/platform_profiles/platform-profile-0/FIV/profile", "value": "performance" },
  [
	{ "type": "Set", "path": "/cpu/cpufreq/FIV/scaling_governor", "value": "powersave" },
	{ "type": "Set", "path": "/cpu/cpufreq/FIV/energy_performance_preference", "value": "performance" },
	{ "type": "Set", "path": "/cpu/cpufreq/FIV/scaling_min_freq_pct", "value": 10 },
	{ "type": "Set", "path": "/cpu/cpufreq/FIV/scaling_max_freq_pct", "value": 100 }
  ],
  [
	{ "type": "Set", "path": "/cpu/intel_pstate/FIV/status", "value": "active" },
	{ "type": "Set", "path": "/cpu/intel_pstate/FIV/hwp_dynamic_boost", "value": 1 },
	{ "type": "Set", "path": "/cpu/intel_pstate/FIV/no_turbo", "value": 0 },
	{ "type": "Set", "path": "/cpu/intel_pstate/FIV/min_perf_pct", "value": 10 },
	{ "type": "Set", "path": "/cpu/intel_pstate/FIV/max_perf_pct", "value": 100 }
  ],
  [
	{ "type": "Set", "path": "/gpu/card1/FIV/gt_min_freq_mhz_pct", "value": 0 },
	{ "type": "Set", "path": "/gpu/card1/FIV/gt_max_freq_mhz_pct", "value": 100 },
	{ "type": "Set", "path": "/gpu/card1/FIV/gt_boost_freq_mhz_pct", "value": 100 }
  ],
  { "type": "Set", "path": "/backlights/intel_backlight/FIV/brightness_pct", "value": 100 }
]
```
**FIV** is a short for feature_interfaces_virtual.
This will give an output like:
```json
[
  {
	"success": 1,
	"response": "performance"
  },
  [
	{
	  "success": 1,
	  "response": {
		"policy1": "powersave",
		"policy0": "powersave",
		"policy4": "powersave",
		"policy3": "powersave",
		"policy2": "powersave",
		"policy5": "powersave"
	  }
	},
	{
	  "success": 1,
	  "response": {
		"policy1": "performance",
		"policy0": "performance",
		"policy4": "performance",
		"policy3": "performance",
		"policy5": "performance",
		"policy2": "performance"
	  }
	},
	{
	  "success": 1,
	  "response": {
		"policy1": 10,
		"policy0": 10,
		"policy3": 10,
		"policy4": 10,
		"policy5": 10,
		"policy2": 10
	  }
	},
	{
	  "success": 1,
	  "response": {
		"policy1": 100,
		"policy3": 100,
		"policy0": 100,
		"policy4": 100,
		"policy5": 100,
		"policy2": 100
	  }
	}
  ],
  [
	{
	  "success": 1,
	  "response": "active"
	},
	{
	  "success": 1,
	  "response": "1"
	},
	{
	  "success": 1,
	  "response": "0"
	},
	{
	  "success": 1,
	  "response": 10
	},
	{
	  "success": 1,
	  "response": 100
	}
  ],
  [
	{
	  "success": 1,
	  "response": 0
	},
	{
	  "success": 1,
	  "response": 100
	},
	{
	  "success": 1,
	  "response": 100
	}
  ],
  {
	"success": 1,
	"response": 100
  }
]
```
Get queries return more detailed responses which makes it easy for example to
write a gui fronted. For example this query:
```json
[
  { "type": "Get", "path": "/batteries/BAT0/FIV/charge_control_start_threshold_pct" },
  { "type": "Get", "path": "/batteries/BAT0/FIV/charge_control_end_threshold_pct" },
  { "type": "Get", "path": "/platform_profiles/platform-profile-0/FIV/profile" },
  [
	{ "type": "Get", "path": "/cpu/cpufreq/FIV/scaling_governor" },
	{ "type": "Get", "path": "/cpu/cpufreq/FIV/energy_performance_preference" },
	{ "type": "Get", "path": "/cpu/cpufreq/FIV/scaling_min_freq_pct" },
	{ "type": "Get", "path": "/cpu/cpufreq/FIV/scaling_max_freq_pct" }
  ],
  [
	{ "type": "Get", "path": "/cpu/intel_pstate/FIV/status" },
	{ "type": "Get", "path": "/cpu/intel_pstate/FIV/hwp_dynamic_boost" },
	{ "type": "Get", "path": "/cpu/intel_pstate/FIV/no_turbo" },
	{ "type": "Get", "path": "/cpu/intel_pstate/FIV/min_perf_pct" },
	{ "type": "Get", "path": "/cpu/intel_pstate/FIV/max_perf_pct" }
  ],
  [
	{ "type": "Get", "path": "/gpu/card1/FIV/gt_min_freq_mhz_pct" },
	{ "type": "Get", "path": "/gpu/card1/FIV/gt_max_freq_mhz_pct" },
	{ "type": "Get", "path": "/gpu/card1/FIV/gt_boost_freq_mhz_pct" }
  ],
  { "type": "Get", "path": "/backlights/intel_backlight/FIV/brightness_pct" }
]
```
Can provide a result like:
```jq
[
  {
	"lower_bound": 0,
	"success": 1,
	"upper_bound": 100,
	"response": 90
  },
  {
	"lower_bound": 0,
	"success": 1,
	"upper_bound": 100,
	"response": 98
  },
  {
	"choices": [
	  "cool",
	  "quiet",
	  "balanced",
	  "performance"
	],
	"success": 1,
	"response": "performance"
  },
  [
	{
	  "success": 1,
	  "response": {
		"policy1": "powersave",
		"policy0": "powersave",
		"policy4": "powersave",
		"policy3": "powersave",
		"policy2": "powersave",
		"policy5": "powersave"
	  }
	},
	{
	  "success": 1,
	  "response": {
		"policy1": "performance",
		"policy0": "performance",
		"policy4": "performance",
		"policy3": "performance",
		"policy5": "performance",
		"policy2": "performance"
	  }
	},
	{
	  "success": 1,
	  "response": {
		"policy1": 10,
		"policy0": 10,
		"policy3": 10,
		"policy4": 10,
		"policy5": 10,
		"policy2": 10
	  }
	},
	{
	  "success": 1,
	  "response": {
		"policy1": 100,
		"policy3": 100,
		"policy0": 100,
		"policy4": 100,
		"policy5": 100,
		"policy2": 100
	  }
	}
  ],
  [
	{
	  "choices": [
		"active",
		"passive",
		"off"
	  ],
	  "success": 1,
	  "response": "active"
	},
	{
	  "choices": [
		"0",
		"1"
	  ],
	  "success": 1,
	  "response": "1"
	},
	{
	  "choices": [
		"0",
		"1"
	  ],
	  "success": 1,
	  "response": "0"
	},
	{
	  "lower_bound": 0,
	  "success": 1,
	  "upper_bound": 100,
	  "response": 10
	},
	{
	  "lower_bound": 0,
	  "success": 1,
	  "upper_bound": 100,
	  "response": 100
	}
  ],
  [
	{
	  "lower_bound": "100",
	  "success": 1,
	  "upper_bound": "1250",
	  "response": 0
	},
	{
	  "lower_bound": "100",
	  "success": 1,
	  "upper_bound": "1250",
	  "response": 100
	},
	{
	  "lower_bound": "100",
	  "success": 1,
	  "upper_bound": "1250",
	  "response": 100
	}
  ],
  {
	"lower_bound": 0,
	"success": 1,
	"upper_bound": "96000",
	"response": 100
  }
]
```

## Example usage
I have a **/desktop/devicemaster.json** file containing:
```json
{
  "PERSISTENT": [
	{ "type": "Set", "path": "/batteries/BAT0/FIV/charge_control_start_threshold_pct", "value": 90 },
	{ "type": "Set", "path": "/batteries/BAT0/FIV/charge_control_end_threshold_pct", "value": 98 }
  ],
  "PERFORMANCE" : [
	{ "type": "Set", "path": "/platform_profiles/platform-profile-0/FIV/profile", "value": "performance" },
	[
	  { "type": "Set", "path": "/cpu/cpufreq/FIV/scaling_governor", "value": "powersave" },
	  { "type": "Set", "path": "/cpu/cpufreq/FIV/energy_performance_preference", "value": "performance" },
	  { "type": "Set", "path": "/cpu/cpufreq/FIV/scaling_min_freq_pct", "value": 10 },
	  { "type": "Set", "path": "/cpu/cpufreq/FIV/scaling_max_freq_pct", "value": 100 }
	],
	[
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/status", "value": "active" },
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/hwp_dynamic_boost", "value": 1 },
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/no_turbo", "value": 0 },
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/min_perf_pct", "value": 10 },
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/max_perf_pct", "value": 100 }
	],
	[
	  { "type": "Set", "path": "/gpu/card1/FIV/gt_min_freq_mhz_pct", "value": 0 },
	  { "type": "Set", "path": "/gpu/card1/FIV/gt_max_freq_mhz_pct", "value": 100 },
	  { "type": "Set", "path": "/gpu/card1/FIV/gt_boost_freq_mhz_pct", "value": 100 }
	],
	{ "type": "Set", "path": "/backlights/intel_backlight/FIV/brightness_pct", "value": 100 }
  ],
  "BALANCED" : [
	{ "type": "Set", "path": "/platform_profiles/platform-profile-0/FIV/profile", "value": "balanced" },
	[
	  { "type": "Set", "path": "/cpu/cpufreq/FIV/scaling_governor", "value": "powersave" },
	  { "type": "Set", "path": "/cpu/cpufreq/FIV/energy_performance_preference", "value": "balance_performance" },
	  { "type": "Set", "path": "/cpu/cpufreq/FIV/scaling_min_freq_pct", "value": 10 },
	  { "type": "Set", "path": "/cpu/cpufreq/FIV/scaling_max_freq_pct", "value": 80 }
	],
	[
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/status", "value": "active" },
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/hwp_dynamic_boost", "value": 0 },
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/no_turbo", "value": 1 },
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/min_perf_pct", "value": 10 },
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/max_perf_pct", "value": 80 }
	],
	[
	  { "type": "Set", "path": "/gpu/card1/FIV/gt_min_freq_mhz_pct", "value": 0 },
	  { "type": "Set", "path": "/gpu/card1/FIV/gt_max_freq_mhz_pct", "value": 75 },
	  { "type": "Set", "path": "/gpu/card1/FIV/gt_boost_freq_mhz_pct", "value": 100 }
	],
	{ "type": "Set", "path": "/backlights/intel_backlight/FIV/brightness_pct", "value": 100 }
  ],
  "BALANCE_POWER" : [
	{ "type": "Set", "path": "/platform_profiles/platform-profile-0/FIV/profile", "value": "quiet" },
	[
	  { "type": "Set", "path": "/cpu/cpufreq/FIV/scaling_governor", "value": "powersave" },
	  { "type": "Set", "path": "/cpu/cpufreq/FIV/energy_performance_preference", "value": "power" },
	  { "type": "Set", "path": "/cpu/cpufreq/FIV/scaling_min_freq_pct", "value": 10 },
	  { "type": "Set", "path": "/cpu/cpufreq/FIV/scaling_max_freq_pct", "value": 60 }
	],
	[
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/status", "value": "active" },
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/hwp_dynamic_boost", "value": 0 },
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/no_turbo", "value": 1 },
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/min_perf_pct", "value": 10 },
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/max_perf_pct", "value": 60 }
	],
	[
	  { "type": "Set", "path": "/gpu/card1/FIV/gt_min_freq_mhz_pct", "value": 0 },
	  { "type": "Set", "path": "/gpu/card1/FIV/gt_max_freq_mhz_pct", "value": 50 },
	  { "type": "Set", "path": "/gpu/card1/FIV/gt_boost_freq_mhz_pct", "value": 75 }
	],
	{ "type": "Set", "path": "/backlights/intel_backlight/FIV/brightness_pct", "value": 10 }
  ],
  "POWER" : [
	{ "type": "Set", "path": "/platform_profiles/platform-profile-0/FIV/profile", "value": "quiet" },
	[
	  { "type": "Set", "path": "/cpu/cpufreq/FIV/scaling_governor", "value": "powersave" },
	  { "type": "Set", "path": "/cpu/cpufreq/FIV/energy_performance_preference", "value": "power" },
	  { "type": "Set", "path": "/cpu/cpufreq/FIV/scaling_min_freq_pct", "value": 10 },
	  { "type": "Set", "path": "/cpu/cpufreq/FIV/scaling_max_freq_pct", "value": 30 }
	],
	[
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/status", "value": "active" },
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/hwp_dynamic_boost", "value": 0 },
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/no_turbo", "value": 1 },
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/min_perf_pct", "value": 10 },
	  { "type": "Set", "path": "/cpu/intel_pstate/FIV/max_perf_pct", "value": 40 }
	],
	[
	  { "type": "Set", "path": "/gpu/card1/FIV/gt_min_freq_mhz_pct", "value": 0 },
	  { "type": "Set", "path": "/gpu/card1/FIV/gt_max_freq_mhz_pct", "value": 50 },
	  { "type": "Set", "path": "/gpu/card1/FIV/gt_boost_freq_mhz_pct", "value": 75 }
	],
	{ "type": "Set", "path": "/backlights/intel_backlight/FIV/brightness_pct", "value": 10 }
  ],
  "QUERY" : [
	{ "return_path": true, "type": "Get", "path": "/batteries/BAT0/FIV/charge_control_start_threshold_pct" },
	{ "return_path": true, "type": "Get", "path": "/batteries/BAT0/FIV/charge_control_end_threshold_pct" },
	{ "return_path": true, "type": "Get", "path": "/platform_profiles/platform-profile-0/FIV/profile" },
	[
	  { "return_path": true, "type": "Get", "path": "/cpu/cpufreq/FIV/scaling_governor" },
	  { "return_path": true, "type": "Get", "path": "/cpu/cpufreq/FIV/energy_performance_preference" },
	  { "return_path": true, "type": "Get", "path": "/cpu/cpufreq/FIV/scaling_min_freq_pct" },
	  { "return_path": true, "type": "Get", "path": "/cpu/cpufreq/FIV/scaling_max_freq_pct" }
	],
	[
	  { "return_path": true, "type": "Get", "path": "/cpu/intel_pstate/FIV/status" },
	  { "return_path": true, "type": "Get", "path": "/cpu/intel_pstate/FIV/hwp_dynamic_boost" },
	  { "return_path": true, "type": "Get", "path": "/cpu/intel_pstate/FIV/no_turbo" },
	  { "return_path": true, "type": "Get", "path": "/cpu/intel_pstate/FIV/min_perf_pct" },
	  { "return_path": true, "type": "Get", "path": "/cpu/intel_pstate/FIV/max_perf_pct" }
	],
	[
	  { "return_path": true, "type": "Get", "path": "/gpu/card1/FIV/gt_min_freq_mhz_pct" },
	  { "return_path": true, "type": "Get", "path": "/gpu/card1/FIV/gt_max_freq_mhz_pct" },
	  { "return_path": true, "type": "Get", "path": "/gpu/card1/FIV/gt_boost_freq_mhz_pct" }
	],
	{ "return_path": true, "type": "Get", "path": "/backlights/intel_backlight/FIV/brightness_pct" }
  ]
}
```
And with this bash script:
```bash
#!/usr/bin/env bash

jq -c .$(jq -r 'keys[]' /desktop/devicemaster.json | dmenu -p mode -l 10) /desktop/devicemaster.json \
	| socat STDIO UNIX-CONNECT:/tmp/devicemaster.socket \
	| jq > /tmp/dmout.json

st -n pop-up -g 120x30 -e $SHELL -c 'nvim /tmp/dmout.json'
```
I change the device "profile".

## Supported devices
Currently I'm working on a Dell Vostro 15 device with 13th gen Intel CPU and without a dGPU. For AMD CPUs, discrete graphics and other devices contributions are wellcome.

Currently DeviceMaster works only with sysfs. In future ACPI and USB devices will be supported too (for example to control keyboard backlights).

Currently DeviceMaster provides only the existing devices. In future "virtual" devices will be supported too. For example on Dell G series laptops fans support "boosts" available through /sys/class/hwmon. DeviceMaster will support "virtual fans" on that devices to directly work with the fans.

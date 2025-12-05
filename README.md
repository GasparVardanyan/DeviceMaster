# DeviceMaster
Device manager for computer/laptop parts in Linux.

## Usage
DeviceMaster::Apps::JRPC enables a JRPC control over a UNIX socket.
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
  "response": {
	"feature_interfaces": {
	  "profile": {
		"writable": "1",
		"__CLASS__": "DeviceMaster::FeatureFileInterface",
		"readable": "1"
	  },
	  "choices": {
		"writable": "",
		"__CLASS__": "DeviceMaster::FeatureFileInterface",
		"readable": "1"
	  },
	  "name": {
		"writable": "",
		"__CLASS__": "DeviceMaster::FeatureFileInterface",
		"readable": "1"
	  }
	},
	"id": "platform-profile-0",
	"__CLASS__": "DeviceMaster::Device::PlatformProfile"
  },
  "success": 1
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
	"response": "",
	"success": 0,
	"error": "invalid data requested"
  },
  {
	"response": "96000",
	"success": 1
  },
  [
	{
	  "response": "0",
	  "success": 1
	},
	{
	  "response": "1",
	  "success": 1
	},
	{
	  "response": "50",
	  "success": 1
	}
  ],
  {
	"response": "10",
	"success": 1
  },
  {
	"response": {
	  "feature_interfaces": {
		"actual_brightness": {
		  "writable": "",
		  "__CLASS__": "DeviceMaster::FeatureFileInterface",
		  "readable": "1"
		},
		"max_brightness": {
		  "writable": "",
		  "__CLASS__": "DeviceMaster::FeatureFileInterface",
		  "readable": "1"
		},
		"brightness": {
		  "writable": "1",
		  "__CLASS__": "DeviceMaster::FeatureFileInterface",
		  "readable": "1"
		}
	  },
	  "id": "intel_backlight",
	  "__CLASS__": "DeviceMaster::Device::Backlight"
	},
	"success": 1
  },
  {
	"response": "active",
	"success": 1
  },
  {
	"response": "5000",
	"success": 1
  }
]
```

## Supported devices
Currently I'm working on a Dell Vostro 15 device with 13th gen Intel CPU and without a dGPU. For AMD CPUs, discrete graphics and other devices contributions are wellcome.

Currently DeviceMaster works only with sysfs. In future ACPI and USB devices will be supported too (for example to control keyboard backlights).

Currently DeviceMaster provides only the existing devices. In future "virtual" devices will be supported too. For example on Dell G series laptops fans support "boosts" available through /sys/class/hwmon. DeviceMaster will support "virtual fans" on that devices to directly work with the fans.

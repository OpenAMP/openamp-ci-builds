# OpenAMP-CI Reference Build
This directory contains other build definitions that may be good for reference or
comparison to the openamp-ci builds.

Setup and use these builds the same as you would the openamp-ci builds.
See the main README.md

All times are for the reference X86 machine defined in the main README.md and
assume empty sstate and download caches.  Warm caches even for other build
configurations can drastically reduce these times.

All the builds below except as notes have also been tested on an arm64 host.

## Generic poky builds for qemuarm64 and qemuarm
(~113 / ~69 min respectively)
```
kas build for-ref/qemuarm64.yml
kas build for-ref/qemuarm.yml
```

## Xen minimal image using Poky meta-virtualization and other requiredayers
Builds for qemuarm64
(~78 min)
```
kas build for-ref/xen.yml
```

## full build for STMP1 Linux on Cortex-A7s using upstream sources (w/patches)
uses meta-st-stm32mp-oss to build upstream kernel, u-boot, etc
(~79 min)
```
kas build for-ref/stm32mp157c-dk2.yml
```

## Xilinx vendor build

NOTE: This build will not work on an arm64 machine

The below script builds the Xilinx QEMU machine with all Xilinx layers and
using the Xilinx versions of Linux, openamp libaries, U-boot etc
(~87 min)
```
./for-ref/xilinx-vendor.sh
```

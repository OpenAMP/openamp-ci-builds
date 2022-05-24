# OpenAMP-CI Reference Build
This directory contains other build definitions that may be good for reference or
comparison to the openamp-ci builds.

Setup and use these builds the same as you would the openamp-ci builds.
See the main README.md

## full build for STMP1 Linux on Cortex-A7s using upstream sources (w/patches)
uses meta-st-stm32mp-oss to build upstream kernel, u-boot, etc
Matches Arnaud's instructions [here](https://github.com/OpenAMP/openamp-system-reference/wiki#multi-rpmsg-services-demo)
(took 67 min)
```
kas build for-ref/stm32mp157c-dk2.yml
```
## a meta-zephyr build for STMP1 M4
uses Arnaud's fork of meta-zephyr to build the new resource table demo
Also matches Arnaud's instructions
(took 13 min)
```
kas build for-ref/zephyr-stm32mp157c-dk2.yml
```

## Generic poky builds for qemuarm and qemuarm64
(~70 min for each)
```
kas build for-ref/qemuarm.yml
kas build for-ref/qemuarm64.yml
```

## Xilinx vendor build
The below script builds the Xilinx QEMU machine with all Xilinx layers and
using the Xilinx versions of Linux, openamp libaries, U-boot etc
(~2 hr)
```
./for-ref/xilinx-vendor.sh
```

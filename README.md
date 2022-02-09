# OpenAMP-CI Builds
This repo contains scripts and configurations for OpenAMP CI builds

This is still a work in progress but if you want to try it:

Start with a fresh VM or container
* You could use your native machine but it is going to install a bunch of stuff
* machine should have at least:
  + 8GB RAM
  + 100GB disk
  + x86_64
  + Ubuntu 20.04
  + sudo access

* any build times mentioned below are on a AWS EC2 machine:
  + m6i.4xlarge X86_64 instance type
  + 8 cores (16 vCPUs)
  + 64GB RAM
  + 1TB SSD (via EBS) (< 250 GB used peak)
  + very fast internet

* I will be testing on aarch64 hosts but trouble is expected on vendor builds

## setup
```
git clone https://github.com/wmamills/openamp-ci-builds.git
cd openamp-ci-builds
scripts/build-host-setup.sh
if ! which kas; then PATH="~/.local/bin:$PATH"; fi
```

## for a quick (< 1 min) test use
```
kas build ci/qemuarm64-test.yml
```

## full build for STMP1 Linux on Cortex-A7s
uses meta-st-stm32mp-oss to build upstream kernel, u-boot, etc  
Matches Arnaud's instructions [here](https://github.com/OpenAMP/openamp-system-reference/wiki#multi-rpmsg-services-demo)  
(took 35 min)
```
kas build ci/stm32mp157c-dk2.yml
```
## a meta-zephyr build for STMP1 M4
uses Arnaud's fork of meta-zephyr to build the new resource table demo
Also matches Arnaud's instructions  
(took 12 min)
```
kas build zephyr-stm32mp157c-dk2.yml
```

## Generic poky builds for qemuarm and qemuarm64
(each took 37 min)
```
kas build ci/qemuarm.yml
kas build ci/qemuarm64.yml
```

## Openamp specific upstream builds
The following are still a work in progress.  They work but still don't do what
I want.  genericarm64 is closer.

These use a fork of meta-openamp in Bill's account.
(Times are similar to poky builds)
```
kas build ci/genericarm64.yml
kas build ci/genericarmv7.yml
```

## Xilinx vendor build
The below script build the Xilinx QEMU machine with all Xilinx layers and
using the Xilinx versions of Linux, openamp libaries, U-boot etc
```
ci/xilinx-vendor.sh
```

## next steps
* going forward I will publish sstate for these builds and then users with
a decent internet connection will be able to reproduce them in a few min
* I will add builds for Xilinx vendor build
* I want to add build that directly uses west and zephyr-sdk for comparison to
meta-zephyr
* I will fix openamp specific build
* I will switch to real genericarm* machine targets
  + meta-arm has generic-arm64 that we should use for the OS
    - we won't include the other layers from meta-arm
  + I will create a meta-arm-extra layer to define generic-armv7
    - hopefully meta-arm will take our suggestions
    - we need this for SystemReady IR testing anyway
  + meta-arm has qemuarm64-secureboot which which might be good for boot firmware but I think it uses EDK2 and we would prefer u-boot (for now)

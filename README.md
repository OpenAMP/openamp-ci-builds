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

* I will be testing on aarch64 hosts but trouble is expected on vendor builds

## setup
```
git clone https://github.com/wmamills/openamp-ci-builds.git
cd openamp-ci-builds
scripts/build-host-setup.sh
if ! which kas; then PATH="~/.local/bin:$PATH"; fi
```

## for a quick (2 min) test use
```
kas build ci/qemuarm64-test.yml
```

## full generic poky build  
will take ~ an hour  
```
kas build ci/qemuarm64-test.yml
```

## full build for STMP1 
uses meta-st-stm32mp-oss to build upstream kernel, u-boot, etc
(will take a couple of hours)
```
kas build ci/stm32mp157c-dk2.yml
```

## next steps
* going forward I will publish sstate for these builds and then users with
a decent internet connection will be able to reproduce them in a few min
* I will add builds for Xilinx vendor build
* I will add openamp specific build

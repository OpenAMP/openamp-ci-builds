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

* any build times mentioned below will be for my build machine:
  + 8 cores (16 vCPUs) i7-11700K @ 3.60GHz
  + 32 GB RAM
  + build disk of 2 TB SATA III HD
  + SSD OS disk
  + 800 Mb/s internet

* I will be testing on aarch64 hosts but trouble is expected on vendor builds

## setup
```
git clone https://github.com/wmamills/openamp-ci-builds.git
cd openamp-ci-builds
scripts/build-host-setup.sh
if ! which kas; then PATH="~/.local/bin:$PATH"; fi
```

## for a quick (< 1 min) test of the setup, use
```
kas build ci/generic-arm64.yml:mixins/quick-test.yml
```

## Openamp upstream builds
OpenAMP CI builds use generic OS images, one for 64 bit systems and one for
32 bit systems.  These builds do not build boot firmware and do not build the
remoteproc firmware.

The arm64 build takes ~28 min to build from scratch with no sstate and no downloads cache.
The armv7 build takes ~56 min under the same conditions.

A complete rebuild from sstate takes <1 min

```
kas build ci/generic-arm64.yml
kas build ci/generic-armv7.yml
```

## other builds

This repo has other builds definitions for handy reference.
See [for-ref/README.md](for-ref/README.md)

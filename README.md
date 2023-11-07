# OpenAMP-CI Builds
This repo contains scripts and configurations for OpenAMP CI builds

Start with a fresh VM or container
* You could use your native machine but it is going to install a bunch of stuff
* machine should have at least:
  + 8GB RAM
  + 100GB disk
  + x86_64 or arm64 (aarch64)
  + Ubuntu 20.04 or Ubuntu 22.04
  + sudo access

* any build times mentioned below will be for my build machine:
  + 8 cores (16 vCPUs) i7-11700K @ 3.60GHz
  + 32 GB RAM
  + build disk of 2 TB SATA III HD
  + SSD OS disk
  + 800 Mb/s internet
  + Ubuntu 20.04

* The builds here are also tested on an arm64 host as follows
  + AWS EC2 c6g.4xlarge instance
  + 16 aarch64 cores (Neoverse-N1)
  + 32 GB RAM
  + 250 GB nvme combined OS and build drive
  + up to 10 Gb/s internet
  + Ubuntu 22.04
  + (build times are similar to the reference host but slightly faster)

It is expected but not tested that an arm64 based macOS machine running
multipass to get Ubuntu should be able to build the these targets as well.

## setup
```
git clone https://github.com/openamp/openamp-ci-builds.git
cd openamp-ci-builds
scripts/build-host-setup.sh
if ! which kas; then PATH="$HOME/.local/bin:$PATH"; fi
```

## for a quick (< 1 min) test of the setup, use
```
kas build ci/generic-arm64.yml:mixins/quick-test.yml
```

## Openamp upstream builds
OpenAMP CI builds use generic OS images, one for 64 bit systems and one for
32 bit systems.  These builds do not build boot firmware and do not build the
remoteproc firmware.

The arm64 build takes ~33 min to build from scratch with no sstate and no downloads cache.
The armv7 build takes ~38 min under the same conditions.

A complete rebuild from sstate takes <1 min

```
kas build ci/generic-arm64.yml
kas build ci/generic-armv7.yml
```

## other builds

This repo has other builds definitions for handy reference.
See [for-ref/README.md](for-ref/README.md)

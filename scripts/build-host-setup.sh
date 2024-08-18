#!/bin/bash

ME=$0
MY_DIR=$(dirname $ME)

# setup host for building
sudo apt-get -qq update

if [ -r ~/.aws/credentials ]; then
    sudo apt-get install -qqy s3fs
    mkdir -p ~/net/openamp-builds
    s3fs -o profile=openamp-builds-rw openamp-builds ~/net/openamp-builds
fi

# Yocto/OE requirements
sudo apt-get install -qqy gawk wget git-core diffstat unzip texinfo \
  build-essential chrpath socat cpio python3 python3-pip \
  python3-pexpect xz-utils debianutils iputils-ping curl git \
  zstd libssl-dev lz4 python3-pip python3-venv

# we need kas
if ! which kas; then
    $MY_DIR/venv-wrapper install self-copy
    $MY_DIR/venv-wrapper install kas kas
fi

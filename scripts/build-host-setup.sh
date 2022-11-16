#!/bin/bash

# setup host for building
sudo apt-get update

if [ -r ~/.aws/credentials ]; then
    sudo apt-get install -y s3fs
    mkdir -p ~/net/openamp-builds
    s3fs -o profile=openamp-builds-rw openamp-builds ~/net/openamp-builds
fi

# Yocto/OE requirements
sudo apt-get install -y gawk wget git-core diffstat unzip texinfo \
  build-essential chrpath socat cpio python3 python3-pip \
  python3-pexpect xz-utils debianutils iputils-ping curl git \
  zstd libssl-dev lz4

# we need kas
if ! which kas; then
    pip3 install kas
    if ! which kas; then
        # fix up for this time, assume .bashrc will get it next time
        PATH=~/.local/bin:$PATH
    fi
fi


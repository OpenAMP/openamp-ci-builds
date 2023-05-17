#!/bin/bash

RELEASE=xlnx-rel-v2022.2

set -e
if [ x"$1" == x"-d" ]; then set -x; shift; fi

# assume we start from the ci-builds project level
# allow override via env var
: ${PRJ_DIR:=$PWD}

# setup host for building
sudo apt-get update

# Yocto/OE requirements
# Xilinx xsct binary needs explictly libtinfo5.
# Ubuntu 20.04 uses libtinfo6 when you install libtinfo-dev
sudo apt-get install -y chrpath diffstat gawk qemu-utils curl \
    build-essential python3-distutils libtinfo5 libtinfo-dev \
    libidn11-dev libgmp3-dev zstd

# repo will work if python is python2 or python3 but it needs to be something
# if the user already has one don't touch it
if ! which python; then
    # if this machine has not set the default, set it to python3
    # (don't pull in python2 if we don't need it)
    sudo apt-get install python-is-python3
fi


REPO=~/.local/bin/repo

# we need repo
if which repo ; then
    # we already have it, use it whereever it came from
    REPO=repo
else
    # we need it, add it to ~/.local/bin and use it from there even if
    # that dir is not in the path
    mkdir -p $(dirname $REPO)
    curl https://storage.googleapis.com/git-repo-downloads/repo > $REPO
    chmod +x $REPO
fi

if [ ! -r ~/.gitconfig ]; then
    git config --global user.name   "OpenAMP CI"
    git config --global user.email  "builder@openampproject.org"
    git config --global color.ui    "auto"
    git config --global color.diff  "auto"
fi

# test repo
echo -n "repo version: "
$REPO --version

# for direct execution,
: ${BUILDDIR:=$PRJ_DIR/build-xilinx-vendor}
XILINX_YOCTO_ROOT=$BUILDDIR
mkdir -p $XILINX_YOCTO_ROOT
cd $XILINX_YOCTO_ROOT

echo "*** getting meta data"
$REPO init -u https://github.com/Xilinx/yocto-manifests.git -b refs/tags/$RELEASE
$REPO sync

# reset to clean in case we have already patched
$REPO forall -c git reset --hard

# setup OE Build
source setupsdk

# at this point the PWD will be $XILINX_YOCTO_ROOT/build

# do real build step
if [ -n "$FAKE_IT" ]; then
    echo "FAKE_IT set, stopping before real build & run"
    exit 0
fi

# this step still seems to be needed in 2021.1
# xilinx-bootbin uses bit file from deploy dir but
# does not depend on bitstream-extraction.do_deploy
#   MACHINE=zcu102-zynqmp bitbake -g openamp-image-minimal
#   grep -Pe 'xilinx-bootbin.*-> "bitstream' task-depends.dot
# gives only:
#"xilinx-bootbin.do_prepare_recipe_sysroot" -> "bitstream-extraction.do_populate_sysroot"
# Note: I lose this race ~50% of the time on a clean build but never from sstate
# also since bitbake does gracefull shutdown, the "missing" bit file is normally
# in the deploy dir after it stops as bitstream-extract.do_deploy has run in the
# graceful shutdown phase.
echo "*** build bit file to avoid race condition"
MACHINE=zcu102-zynqmp bitbake virtual/bitstream

echo "*** building image for zcu102"
MACHINE=zcu102-zynqmp bitbake openamp-image-minimal

# The kv260 BOOT.bin does not have any bit file so no race condition
echo "*** building image for kv260"
MACHINE=kv260-starter-kit bitbake openamp-image-minimal

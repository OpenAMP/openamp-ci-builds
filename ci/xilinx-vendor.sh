#!/bin/bash

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
    build-essential python3-distutils libtinfo5 libidn11-dev

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
$REPO init -u git://github.com/Xilinx/yocto-manifests.git -b rel-v2021.2
$REPO sync
source setupsdk

# at this point the PWD will be $XILINX_YOCTO_ROOT/build

# local.conf mods
echo "*** mod local.conf"
CONF=$XILINX_YOCTO_ROOT/build/conf/local.conf
echo "IMAGE_INSTALL_append_zynqmp += \" kernel-module-zynqmp-r5-remoteproc\"" >>$CONF
echo "IMAGE_INSTALL_append = \" packagegroup-petalinux-openamp\"" >> $CONF
echo "IMAGE_INSTALL_append+= \"openssh openssh-sshd openssh-sftp openssh-sftp-server\"" >> $CONF

echo "*** hack QEMU config"
# Hack the QEMU config for user mode networking w/ TFTP
: ${QEMU_TFTP:=$PRJ_DIR/tftp/zcu102}
: ${QEMU_SSH_PORT:=1114}
QEMU_DIR=$XILINX_YOCTO_ROOT/sources/meta-xilinx/meta-xilinx-bsp/conf/machine
QEMU_CONF=$QEMU_DIR/zcu102-zynqmp.conf
QEMU_NET="QB_NETWORK_DEVICE = \"-net nic -net nic -net nic -net nic,netdev=eth0"
QEMU_NET="$QEMU_NET -netdev user,id=eth0,hostfwd=tcp:: $QEMU_SSH_PORT-:22,tftp=$QEMU_TFTP\""
if [ ! -r $QEMU_CONF.orig ]; then
    # first run save what we are starting with
    cp $QEMU_CONF $QEMU_CONF.orig
else
    # other reset to orig
    cp $QEMU_CONF.orig $QEMU_CONF
fi
echo "$QEMU_NET" >> $QEMU_CONF

# get PMU ROM
if [ ! -r $DEPLOY_DIR/pmu-rom.elf ]; then
    echo "*** get PMU ROM"
    DEPLOY_DIR=$XILINX_YOCTO_ROOT/build/tmp/deploy/images/zcu102-zynqmp
    mkdir -p $DEPLOY_DIR
    wget https://www.xilinx.com/bin/public/openDownload?filename=PMU_ROM.tar.gz -O PMU_ROM.tar.gz
    tar -xvzf PMU_ROM.tar.gz
    cp -a  PMU_ROM/pmu-rom.elf $DEPLOY_DIR/pmu-rom.elf
fi

# modify DT
echo "*** modify DT"
DTS_ADD1=$PRJ_DIR/files/zcu102-rproc-adder.dtsi
DTS_BASE_DIR=$XILINX_YOCTO_ROOT/build/workspace/sources/device-tree/device_tree
DTS_BASE_DIR=$DTS_BASE_DIR/data/kernel_dtsi/2021.2
DTS_BASE=$DTS_BASE_DIR/zynqmp/zynqmp.dtsi
# is this the first time through?cd
if [ ! -r $DTS_BASE.orig ]; then
    # check it out for dev/hacking
    echo "****** devtool modify"
    MACHINE=zcu102-zynqmp devtool modify device-tree

    # keep track of the original
    # and record the fact that we have already checked out
    cp $DTS_BASE $DTS_BASE.orig
fi
cat $DTS_BASE.orig $DTS_ADD1 >$DTS_BASE

# mystery step
echo "YAML_DT_BOARD_FLAGS='{BOARD zcu102-rev1.0}'" >> $CONF

# force rebuild DTB
echo "****** DT cleanall"
MACHINE=zcu102-zynqmp bitbake -f -c cleanall device-tree
echo "****** DT build"
MACHINE=zcu102-zynqmp bitbake device-tree

# do real build step
if [ -n "$FAKE_IT" ]; then
    echo "FAKE_IT set, stopping before real build & run"
    exit 0
fi

echo "*** building image"
MACHINE=zcu102-zynqmp bitbake openamp-image-minimal

# run it
echo "*** running image"
MACHINE=zcu102-zynqmp bitbake openamp-image-minimal

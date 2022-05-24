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
$REPO init -u https://github.com/Xilinx/yocto-manifests.git -b rel-v2022.1
$REPO sync
source setupsdk

# at this point the PWD will be $XILINX_YOCTO_ROOT/build

# local.conf mods
echo "*** mod local.conf"
CONF=$XILINX_YOCTO_ROOT/build/conf/local.conf
if [ ! -r $CONF.orig ]; then
    # first run save what we are starting with
    cp $CONF $CONF.orig
else
    # other reset to orig
    cp $CONF.orig $CONF
fi
echo 'IMAGE_INSTALL:append:zynqmp += " kernel-module-zynqmp-r5-remoteproc"' >>$CONF
echo 'IMAGE_INSTALL:append = " packagegroup-petalinux-openamp"' >> $CONF
echo 'IMAGE_INSTALL:append = " openssh openssh-sshd openssh-sftp openssh-sftp-server"' >> $CONF
echo 'EXTRA_IMAGE_FEATURES += " debug-tweaks"' >> $CONF

# configure board specific rootfs tweaks
echo "YAML_DT_BOARD_FLAGS:zcu102='{BOARD zcu102-rev1.0}'" >> $CONF
echo "YAML_DT_BOARD_FLAGS:k26='{BOARD zynqmp-sm-k26-reva}'" >> $CONF

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

echo "*** hack k26 openamp.dtsi"
# Hack the k26 openamp device tree source overlay
K26_OA_DTSI=$XILINX_YOCTO_ROOT/sources/meta-som/recipes-bsp/device-tree/files/openamp.dtsi
if [ ! -r $K26_OA_DTSI.orig ]; then
    # first run save what we are starting with
    cp $K26_OA_DTSI $K26_OA_DTSI.orig
fi
cp $PRJ_DIR/files/openamp_2022_1_fix.dtsi $K26_OA_DTSI

# get PMU ROM
# disabled, 2022.1 already does this
if false; then
if [ ! -r $DEPLOY_DIR/pmu-rom.elf ]; then
    echo "*** get PMU ROM"
    DEPLOY_DIR=$XILINX_YOCTO_ROOT/build/tmp/deploy/images/zcu102-zynqmp
    mkdir -p $DEPLOY_DIR
    wget https://www.xilinx.com/bin/public/openDownload?filename=PMU_ROM.tar.gz -O PMU_ROM.tar.gz
    tar -xvzf PMU_ROM.tar.gz
    cp -a  PMU_ROM/pmu-rom.elf $DEPLOY_DIR/pmu-rom.elf
fi
fi

# modify DT for zcu102
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

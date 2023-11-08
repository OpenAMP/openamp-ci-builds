#!/bin/bash

# set the default but allow override from the user environment
: ${RELEASE:=xlnx-rel-v2023.2}
: ${REL_TYPE:=tag}

# the following is a grep key, don't change it
# prjtools: support get-info
if [ x"$1" == x"--get-info" ]; then
    echo "BUILD_DIR=build-xilinx-vendor/build"
    echo "OE_BRANCH=$RELEASE"
    exit 0
fi

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

case $REL_TYPE in
tag)
    REPO_REF=refs/tags/$RELEASE
    ;;
branch)
    REPO_REF=$RELEASE
    ;;
*)
    echo "Bad REL_TYPE=$REL_TYPE" && false
    ;;
esac

echo "*** getting meta data"
$REPO init -u https://github.com/Xilinx/yocto-manifests.git -b $REPO_REF
$REPO sync

# reset to clean in case we have already patched
$REPO forall -c git reset --hard

# setup OE Build
source setupsdk

# at this point the PWD will be $XILINX_YOCTO_ROOT/build
echo 'IMAGE_INSTALL:append = " \
    packagegroup-petalinux-openamp \
    kernel-module-zynqmp-r5-remoteproc \
    kernel-module-rpmsg-ctrl \
    kernel-module-rpmsg-ns \
    kernel-module-virtio-rpmsg-bus \
" ' >>conf/local.conf

# do real build step
if [ -n "$FAKE_IT" ]; then
    echo "FAKE_IT set, stopping before real build & run"
    exit 0
fi

# this step is needed for release < 2023.1
# found in 2021.1 and at least 1 earlier release
#
# NOTE: This race seems to have been fixed in 2023.1
# Keeping the workaround for older releases
#
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
#
# In 2023.1:
# The dependencies are still as described above but bootbin has been changed to
# pull the bit file from RECIPE_SYSROOT instead of DEPLOY.
#
# cd meta-xilinx/meta-xilinx-core/recipes-bsp/bootbin
# git diff xlnx-rel-v2022.2 xlnx-rel-v2023.1 machine-xilinx-zynqmp.inc
# changed in commit edf1b5f64b77fffeac0d43aaa41f5484382b4e06
# on 2022-10-25
echo "*** build bit file to avoid race condition"
MACHINE=zcu102-zynqmp bitbake virtual/bitstream

echo "*** building image for zcu102"
MACHINE=zcu102-zynqmp bitbake openamp-image-minimal

# The kv260 BOOT.bin does not have any bit file so no race condition
echo "*** building image for kv260"
MACHINE=k26-smk-kv bitbake openamp-image-minimal

# There are a lot of variations of the file systems that we really don't need
# This loses no real value and decreases the deploy/image dir
# before w/  sparse files   1.3 GB
# before w/o sparse files   3.7 GB
# after                     401 MB
trim_deploy() {
    SAVE_PWD=$PWD
    for i in ./deploy/images/*; do
        if ! test -d $i; then continue; fi
        echo "Triming $i"
        cd $i

        # make sure we have a .wic.xz for each wic
        # zcu102 only builds a .wic.qemu-sd
        # kria builds .wic .wic.qemu-sd and wic.xz
        for f in *.wic*; do
            #echo "f=$f"
            base=${f%.wic*}
            if [ ! -e $base.wic.xz ]; then
                if [ -h $f ]; then
                    f_link=$(readlink $f)
                    f_link_base=${f_link%.wic*}
                    echo "ln -s $f_link_base.wic.xz $base.wic.xz"
                    ln -s $f_link_base.wic.xz $base.wic.xz
                elif [ -f $f ]; then
                    echo "xz -zc $f >$base.wic.xz"
                    xz -zc $f >$base.wic.xz
                fi
            fi
        done

        # we have .wic.xz .cpio.gz .tar.gz
        # get rid of the redundant or trivial transforms
        # (tar to cpio is also pretty trivial but cpio is very useful so keep)
        FILE_LIST=$(shopt -s nullglob; echo *.wic.qemu-sd *.wic *.ext4 *.jffs2 *.cpio *.cpio.gz.u-boot)
        if [ -n "$FILE_LIST" ]; then
            echo rm -rf $FILE_LIST
            rm -rf $FILE_LIST
        fi

        cd qemu-hw-devicetrees
        echo "Deleting " \
            "$(find . -name "board-versal-*" | wc | awk -e '{ print $1 }' ) " \
            "qemu-hw-devicetree Files"
        find . -name "board-versal-*" | xargs rm -rf
        cd $SAVE_PWD
    done
}

(cd tmp; trim_deploy)

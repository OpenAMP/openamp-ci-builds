#!/bin/bash

echo "post-build for PWD=$PWD CONTEXT=$CONTEXT"

# Nothing to do on remote side of remote build
if [ x"$CONTEXT" == x"remote" ]; then
    exit 0
fi

# if we don't have an FTP deploy dir, then nothing to do
if [ x"$DEPLOY_TFTP_DIR_BASE" == x"" ]; then
    exit 0
fi

M=$(basename $BUILD_CONFIG)
L=build-${BUILD_CONFIG_FLAT}-latest
LINK=$(readlink $L)

PRJ=openamp-ci-2405

case $BUILD_CONFIG_FLAT in
"ci-generic-arm64"|"ci-genericarm64"|"for-ref-xilinx-vendor")
    BOARD=kv260
    ;;
"ci-generic-armv7a"|"ci-genericarmv7a"|"for-ref-stm32mp157c-dk2")
    BOARD=stmp1
    ;;
*)
    echo "Unknown config $BUILD_CONFIG_FLAT, skipping deploy"
    exit
esac

D=$DEPLOY_TFTP_DIR_BASE/${BOARD}-${PRJ}/${BUILD_CONFIG_FLAT}-latest

echo "Deploy $L ($LINK) to $D"

shopt -s nullglob

mkdir -p $D
rm -rf $D/Image*
rm -rf $D/modules*.tgz
rm -rf $D/*.rootfs*.tar.gz
rm -rf $D/kernel-dev*.rpm
cp -a $L/deploy/images/${M}/* $D/
for m in $M ${M/-/_}; do
    for p in rpm ipk deb; do
        for f in $L/deploy/$p/$m/kernel-dev*.$p; do
            if [ -r $f ]; then
                cp -a $f $D/
            fi
        done
    done
done
echo $LINK >$D/info.txt
ln -sf ../make-targets-helper-oe-build $D/make-targets-helper
make-image-targets $D
echo "Deploy done $L ($LINK) to $D"

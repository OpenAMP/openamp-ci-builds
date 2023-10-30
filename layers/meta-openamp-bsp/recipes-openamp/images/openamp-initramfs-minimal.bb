# Simple initramfs image intended to be a standalone cpio based fs
# This is NOT a rootfs finder/early init

DESCRIPTION = "Small cpio based initramfs that is standalone and everything we need to test \
OpenAMP features."

PACKAGE_INSTALL = "\
packagegroup-core-boot module-init-tools shadow \
rpmsg-echo-test rpmsg-mat-mul rpmsg-proxy-app rpmsg-utils \
${PACKAGE_INSTALL_EXTRAS} \
"
PACKAGE_EXCLUDE = "kernel-image-* linux-firmware* grub-*"

# kernel modules are NOT excluded because,
# if you use the default kernel, they are useful, if not, you need to tweak the image anyway
# allows the module.dep* files to be calculated at build time instead of boot time

# we need debug-tweaks and other things, rely on user discretion to not junk this up
#IMAGE_FEATURES = ""

export IMAGE_BASENAME = "${MLPREFIX}openamp-initramfs-minimal"
IMAGE_NAME_SUFFIX ?= ""
IMAGE_LINGUAS = ""

LICENSE = "MIT"

IMAGE_FSTYPES = "${INITRAMFS_FSTYPES}"
inherit core-image

IMAGE_ROOTFS_SIZE = "8192"
IMAGE_ROOTFS_EXTRA_SPACE = "0"

# Use the same restriction as initramfs-module-install
COMPATIBLE_HOST = '(x86_64.*|i.86.*|arm.*|aarch64.*)-(linux.*|freebsd.*)'

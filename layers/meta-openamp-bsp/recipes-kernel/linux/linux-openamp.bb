SUMMARY = "Linux kernel for OpenAMP testing and upstream dev"

inherit kernel
require recipes-kernel/linux/linux-yocto.inc

SRC_REPO = "github.com/wmamills/linux-openamp-staging.git"
SRC_URI = "git://${SRC_REPO};protocol=https;nocheckout=1;name=machine;nobranch=1;branch=openamp-staging-6.0"

SRC_URI:append = " file://openamp-bsp-kmeta;type=kmeta;name=openamp-bsp-kmeta;destsuffix=openamp-bsp-kmeta"

LINUX_VERSION ?= "6.0"
LINUX_VERSION_EXTENSION:append = "-openamp"

# Modify SRCREV to a different commit hash in a copy of this recipe to
SRCREV="openamp-staging-6.0"

PV = "${LINUX_VERSION}+git${SRCPV}"

# Override COMPATIBLE_MACHINE to include your machine in a copy of this recipe
# file. Leaving it empty here ensures an early explicit build failure.
COMPATIBLE_MACHINE = "generic-arm64|generic-armv7a|qemu-arm64|qemu-arm32"

KERNEL_DANGLING_FEATURES_WARN_ONLY = "1"
KERNEL_VERSION_SANITY_SKIP="1"

KERNEL_FEATURES:qemuarm64:append = "cfg/openamp-bsp-generic-arm64.scc"
KERNEL_FEATURES:generic-arm64:append = "cfg/openamp-bsp-generic-arm64.scc"
KERNEL_FEATURES:qemuarm:append = "cfg/openamp-bsp-generic-armv7a.scc"
KERNEL_FEATURES:generic-armv7a:append = "cfg/openamp-bsp-generic-armv7a.scc"

# v5.6 and later tacked on two new lines, one blank and one that just state the obvious.
# ""
#
# All contributions to the Linux Kernel are subject to this COPYING file.
# ""
# we want to work with historical tags like v4.19.262, so limit to common part
LIC_FILES_CHKSUM = "file://COPYING;endline=18;md5=bbea815ee2795b2f4230826c0c6b8814"

#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

ROOTFS=${OUTDIR}/rootfs

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
	make -j"$(nproc)" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
	make -j"$(nproc)" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
	make -j"$(nproc)" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
	make -j"$(nproc)" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"
cp "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" "${OUTDIR}/Image"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p ${OUTDIR}/rootfs
cd rootfs
mkdir -p bin dev etc lib lib64 proc sbin sys tmp usr usr/sbin usr/bin usr/lib var var/log home

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
	make distclean
	make defconfig
	make -j"$(nproc)" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
	make -j"$(nproc)" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} CONFIG_PREFIX=${OUTDIR}/rootfs install
else
    cd busybox
fi

# TODO: Make and install busybox
make distclean
make defconfig
make -j"$(nproc)" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make -j"$(nproc)" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} CONFIG_PREFIX=${OUTDIR}/rootfs install

echo "Library dependencies"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
LIBM="/opt/arm-gnu-toolchain-15.3.rel1-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/lib64/libm.so.6"
LIBC="/opt/arm-gnu-toolchain-15.3.rel1-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/lib64/libc.so.6"
LIBRESOLVE="/opt/arm-gnu-toolchain-15.3.rel1-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/lib64/libresolv.so.2"
LDLINUXAARCH="/opt/arm-gnu-toolchain-15.3.rel1-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/lib/ld-linux-aarch64.so.1"

cp "${LIBM}" "${ROOTFS}/lib"
cp "${LIBC}" "${ROOTFS}/lib"
cp "${LIBRESOLVE}" "${ROOTFS}/lib"
cp "${LDLINUXAARCH}" "${ROOTFS}/lib"

cp "${LIBM}" "${ROOTFS}/lib64"
cp "${LIBC}" "${ROOTFS}/lib64"
cp "${LIBRESOLVE}" "${ROOTFS}/lib64"
cp "${LDLINUXAARCH}" "${ROOTFS}/lib64"


# TODO: Make device nodes
sudo mknod -m 666 ${ROOTFS}/dev/null c 1 3
sudo mknod -m 600 ${ROOTFS}/dev/console c 5 1

# TODO: Clean and build the writer utility
cd ${FINDER_APP_DIR}
make clean
make CROSS_COMPILE=${CROSS_COMPILE}


cp "${FINDER_APP_DIR}/writer" "${ROOTFS}/home"
cp "${FINDER_APP_DIR}/finder.sh" "${ROOTFS}/home"
cp "${FINDER_APP_DIR}/finder-test.sh" "${ROOTFS}/home"
cp "${FINDER_APP_DIR}/autorun-qemu.sh" "${ROOTFS}/home"
cp -rL "${FINDER_APP_DIR}/conf" "${ROOTFS}/home/"
chmod +x "${ROOTFS}/home/writer"
chmod +x "${ROOTFS}/home/finder.sh"
chmod +x "${ROOTFS}/home/finder-test.sh"
chmod +x "${ROOTFS}/home/autorun-qemu.sh"

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs

# TODO: Chown the root directory
sudo chown -R root:root ${ROOTFS}
# TODO: Create initramfs.cpio.gz
  cd ${ROOTFS}
  find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
  cd ${OUTDIR}
  gzip -f initramfs.cpio

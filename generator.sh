#!/bin/bash
# Author: Yevgeniy Goncharov aka xck, http://sys-admin.k
# Script for generate kickstart CentOS image
#
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

# Variables
# ---------------------------------------------------\
CENTOS_RELEASE="7"
MIRROR=" http://mirror.yandex.ru/centos/$CENTOS_RELEASE/isos/x86_64/"
MOUNT_ISO_FOLDER="/mnt/iso"
EXTRACT_ISO_FOLDER="/tmp/centos_custom"


# Get Minimal iso name
echo "Get ISO image from mirror - $MIRROR"
DOWNLOAD_ISO=`curl -s $MIRROR | grep -i "minimal.*.iso" | grep -Po '(?<=href=")[^"]*(?=")'`

# Download iso
if [[ ! -f $SCRIPT_PATH/images/$DOWNLOAD_ISO ]]; then
  # If file not exist
  echo "Download image - $DOWNLOAD_ISO"
  wget $MIRROR$DOWNLOAD_ISO -P $SCRIPT_PATH/images
else
  echo "File already downloaded"
fi

# Create mount folder for downloaded image
if [[ ! -d $MOUNT_ISO_FOLDER ]]; then
  mkdir $MOUNT_ISO_FOLDER
fi

if [[ ! -d $EXTRACT_ISO_FOLDER ]]; then
  mkdir $EXTRACT_ISO_FOLDER
fi

# Mount image and extract
mount $SCRIPT_PATH/images/$DOWNLOAD_ISO $MOUNT_ISO_FOLDER
cp -rp $MOUNT_ISO_FOLDER/* $EXTRACT_ISO_FOLDER

# Copy config to extract iso folder
cp $SCRIPT_PATH/configs/ks.cfg $EXTRACT_ISO_FOLDER


sed -i '/menu default/d' $EXTRACT_ISO_FOLDER/isolinux/isolinux.cfg

sed -i '/label check/i \
label auto \
  menu label ^Auto install CentOS Linux 7 \
  kernel vmlinuz \
  menu default \
  append initrd=initrd.img inst.ks=cdrom:/dev/cdrom:/ks.cfg \
  # end' $EXTRACT_ISO_FOLDER/isolinux/isolinux.cfg

# Make new image
mkisofs -o $SCRIPT_PATH/images/centos-7-custom.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -V 'CentOS 7 x86_64' -boot-load-size 4 -boot-info-table -R -J -v -T $EXTRACT_ISO_FOLDER


# Post action
umount $MOUNT_ISO_FOLDER
rm -rf $EXTRACT_ISO_FOLDER



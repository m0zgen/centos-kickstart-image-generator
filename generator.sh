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
NEW_IMAGE_NAME="centos-7-custom"

# Colors
GREEN="\033[0;32m"
CLS='\033[0m'

# Get Minimal iso name
echo -e "${GREEN}Get ISO image from mirror - $MIRROR${CLS}"
DOWNLOAD_ISO=`curl -s $MIRROR | grep -i "minimal.*.iso" | grep -Po '(?<=href=")[^"]*(?=")'`

# Download iso
download_image()
{
  echo -e "${GREEN}Download image - $DOWNLOAD_ISO${CLS}"
  wget $MIRROR$DOWNLOAD_ISO -P $SCRIPT_PATH/images
}


if [[ ! -d $SCRIPT_PATH/images ]]; then
  mkdir $SCRIPT_PATH/images
  download_image
else
  if [[ ! -f $SCRIPT_PATH/images/$DOWNLOAD_ISO ]]; then
    # If file not exist
    download_image
  else
    echo -e "${GREEN}File already downloaded${CLS}"
  fi
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

# Change default menu to Auto menu
sed -i '/menu default/d' $EXTRACT_ISO_FOLDER/isolinux/isolinux.cfg

sed -i '/label check/i \
label auto \
  menu label ^Auto install CentOS Linux 7 \
  kernel vmlinuz \
  menu default \
  append initrd=initrd.img inst.ks=cdrom:/dev/cdrom:/ks.cfg \
  # end' $EXTRACT_ISO_FOLDER/isolinux/isolinux.cfg

# Make new image
echo -e "${GREEN}Generate iso${CLS}"
mkisofs -o $SCRIPT_PATH/images/$NEW_IMAGE_NAME.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -V '$NEW_IMAGE_NAME' -boot-load-size 4 -boot-info-table -R -J -v -T $EXTRACT_ISO_FOLDER


# Post action
echo -e "${GREEN}Umount $MOUNT_ISO_FOLDER${CLS}"
umount $MOUNT_ISO_FOLDER
echo -e "${GREEN}Delete $EXTRACT_ISO_FOLDER${CLS}"
rm -rf $EXTRACT_ISO_FOLDER

echo -e "${GREEN}Done! New autoimage destination - $SCRIPT_PATH/images/$NEW_IMAGE_NAME.iso${CLS}"

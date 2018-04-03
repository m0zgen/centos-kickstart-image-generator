#!/bin/bash
# Author: Yevgeniy Goncharov aka xck, http://sys-adm.in
# Script for generate kickstart CentOS image
#
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)
ME=`basename "$0"`

# Variables for ISO download 
# -------------------------------------------------------------------------------------------\
CENTOS_RELEASE="7"
MIRROR=" http://mirror.yandex.ru/centos/$CENTOS_RELEASE/isos/x86_64/"
MOUNT_ISO_FOLDER="/mnt/iso"
EXTRACT_ISO_FOLDER="/tmp/centos_custom"
NEW_IMAGE_NAME="centos-7-custom-minimal"

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
CLS='\033[0m'

# Info
# -------------------------------------------------------------------------------------------\
USAGE="
USAGE:
    sudo ./$ME
    sudo ./$ME --move-iso ~/Downloads/iso/
"
HELP="You can use script with arguments

OPTIONS:
    --help          This help
    --copy-iso      Copy generated ISO to your destination (for example: VirtualBox or KVM iso folder)
    --move-iso      Move generated ISO to your destination
"

# Determine OS
if [[ -e /etc/debian_version ]]; then
	OS="debian"
	ISOPACKAGE="genisoimage"
	echo "This distro is $OS"
elif [[ -e /etc/fedora-release ]]; then
	OS="fedora"
	ISOPACKAGE="mkisofs"
	echo "This distro is $OS"
elif [[ -e /etc/centos-release || -e /etc/redhat-release || -e /etc/system-release ]]; then
	OS="centos"
	ISOPACKAGE="mkisofs"
	echo "This distro is $OS"
else
	echo "This OS no supported by this script. Sorry. Supported distro: Debian, CentOS, Fedora"
	exit 4
fi

# Functions
# -------------------------------------------------------------------------------------------\
# Copy ISO
copy-iso(){
  echo "Copy ISO to $1"
  cp $SCRIPT_PATH/images/$NEW_IMAGE_NAME.iso $1
}

# Move ISO
move-iso(){
  echo "Move ISO to $1"
  mv $SCRIPT_PATH/images/$NEW_IMAGE_NAME.iso $1
}

# Function download with Wget
download_image()
{
  echo -e "${GREEN}Download image - $DOWNLOAD_ISO${CLS}"
  wget $MIRROR$DOWNLOAD_ISO -P $SCRIPT_PATH/images
}

# Let's Begin
# -------------------------------------------------------------------------------------------\
# Get Minimal iso name
echo -e "${GREEN}Get ISO image from mirror - $MIRROR${CLS}"
DOWNLOAD_ISO=`curl -s $MIRROR | grep -i "minimal.*.iso" | grep -Po '(?<=href=")[^"]*(?=")'`

# Check folder and downloaded ISO exist
# -------------------------------------------------------------------------------------------\
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

# Check mount, extract ISO folders
# -------------------------------------------------------------------------------------------\
if [[ ! -d $MOUNT_ISO_FOLDER ]]; then
  mkdir $MOUNT_ISO_FOLDER
fi

if [[ ! -d $EXTRACT_ISO_FOLDER ]]; then
  mkdir $EXTRACT_ISO_FOLDER
fi

# Mount image and extract
# -------------------------------------------------------------------------------------------\
mount $SCRIPT_PATH/images/$DOWNLOAD_ISO $MOUNT_ISO_FOLDER
cp -rp $MOUNT_ISO_FOLDER/* $EXTRACT_ISO_FOLDER

# Copy config to extract iso folder
cp $SCRIPT_PATH/configs/ks.cfg $EXTRACT_ISO_FOLDER

# Boot menu changes
# -------------------------------------------------------------------------------------------\
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
# -------------------------------------------------------------------------------------------\
echo -e "${GREEN}Generate iso${CLS}"

if [[ $OS = "centos" ]]; then
  echo "CentOS Detected..."
  # Check ind install $ISOPACKAGE
  if ! rpm -qa | grep -q $ISOPACKAGE; then
    yum install $ISOPACKAGE -y
  fi
fi

if [[ $OS = "fedora" ]]; then
  echo "Fedora Detected..."
  # Check ind install $ISOPACKAGE
  if ! rpm -qa | grep -q $ISOPACKAGE; then
    dnf install $ISOPACKAGE -y
  fi
fi

if [[ $OS = "debian" ]]; then
  echo "Debian Detected..."
  # Add check ind install $ISOPACKAGE
fi


# mkisofs -o $SCRIPT_PATH/images/$NEW_IMAGE_NAME.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -V '$NEW_IMAGE_NAME' -boot-load-size 4 -boot-info-table -R -J -v -T $EXTRACT_ISO_FOLDER
genisoimage -o $SCRIPT_PATH/images/$NEW_IMAGE_NAME.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -V '$NEW_IMAGE_NAME' -boot-load-size 4 -boot-info-table -R -J -v -T $EXTRACT_ISO_FOLDER

# Post action
# -------------------------------------------------------------------------------------------\
echo -e "${GREEN}Umount $MOUNT_ISO_FOLDER${CLS}"
umount $MOUNT_ISO_FOLDER
echo -e "${GREEN}Delete $EXTRACT_ISO_FOLDER${CLS}"
rm -rf $EXTRACT_ISO_FOLDER

echo -e "${RED}Done!${CLS} ${GREEN}New autoimage destination - $SCRIPT_PATH/images/$NEW_IMAGE_NAME.iso${CLS}"

# Params
while test $# -gt 0
do
    case "$1" in
        --help)
              echo -e "$USAGE"
              echo -e "$HELP"
              exit
            ;;
        --copy-iso)
              if [[ -z $2 ]]; then
                echo "Argument is empty"
              else
                copy-iso $2
              fi
            ;;
        --move-iso)
              if [[ -z $2 ]]; then
                echo "Argument is empty"
              else
                move-iso $2
              fi
            ;;
        #--*) echo "bad option $1"
        #    ;;
        #*) echo "argument $1"
        #    ;;
    esac
    shift
done

exit 0

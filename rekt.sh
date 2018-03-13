#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

if [ -d mnt ]; then
	echo '[ Cleaning up mnt/ ]'
	umount mnt
	rmdir mnt
fi
if [ -d extracted ]; then
	echo '[ Cleaning up extracted/ ]'
	rm -rf extracted
fi

mkdir mnt
mount "$1" mnt

if [ -z "$2" ]
  then
    FNAME="initramfs-linux"
  else
  	FNAME=$2
fi

echo '[ Backing up initramfs ]'
cp mnt/${FNAME}.img /${FNAME}-backup.img

echo '[ Extracting initramfs-linux.img ]'
mkdir extracted
pushd extracted
lsinitcpio -x ../mnt/${FNAME}.img

echo '[ Patching encrypt hook ]'
cp ../encrypt hooks/encrypt

echo '[ Repacking initramfs-linux.img ]'
find . -mindepth 1 -printf '%P\0' | LANG=C bsdcpio -0 -o -H newc --quiet | gzip > ../${FNAME}.img

echo 'Please inspect and manually copy the initramfs to mnt'

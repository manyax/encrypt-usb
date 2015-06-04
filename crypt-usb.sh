#!/bin/bash

#first check if I am root
if ! [ $(id -u) = 0 ]; then
   echo "You must be root to do this." 1>&2
   exit 100
else
	#Find usb device
	while read mtabline
		do
  			device=`echo $mtabline | awk '{print $1}'`
  			udevline=`udevadm info -q path -n $device 2>&1 |grep usb` 
  			if [ $? == 0 ] ; then
    		echo -e "\e[91mUSB disk located at:\e[0m $device"
  			fi
	done < /etc/mtab
	echo -e "\e[91m!!! Do not remove USB drive !!!\e[0m"
	#create random keyfile
	dd if=/dev/random of=/tmp/keyfile bs=1 count=256
	#unmount device
	umount $device
	#format usb
	echo -e "\e[91mFormat usb\e[0m"	
	cryptsetup luksFormat -q $device --key-file /tmp/keyfile
	echo "done"
	#Open usb
	cryptsetup luksOpen $device crypt --key-file /tmp/keyfile
	echo "Open device"
	#show status and make file system
	cryptsetup -v status crypt
	echo -e "\e[36mCreate file system on crypted device\e[0m"
	mkfs.ext4 -q /dev/mapper/crypt
	echo "Done"
	#mount device
	mkdir -p /media/crypt
	mount /dev/mapper/crypt /media/crypt
	#copy files
	echo -e "\e[91mBacking up your important files\e[0m"
	cp /home/manyax/test.txt /media/crypt
	echo "Done"
	sleep 5
	#unmount files
	echo "Unmount usb device"
	umount /dev/mapper/crypt
	#close luks
	echo -e "\e[36mClose crypt\e[0m"
	cryptsetup luksClose crypt
	
	#copy key file
	echo -e "\e[91Copy your random security file to a secure location\e[0m"
	sshpass -p 'password' scp /tmp/keyfile manyax@manyax.net:/home/manyax/securelocation/ 
	echo -e "\e[36mAll Done\e[0m"
fi	

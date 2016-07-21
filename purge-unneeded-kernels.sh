#!/bin/bash
# Purges old kernels
# Keeps base (oldest) and 2 most recent
# deploy and crontab as: @reboot /root/purge-unneeded-kernels.sh

## Steps:
# show all installed packages
# select all installed images
# select only package name
# remove current and base kernel from list
# remove two recent kernels from list
# capture image version
# do it
dpkg --get-selections | \
  grep 'linux-image-*' | \
  awk '{print $1}' | \
  egrep -v "linux-image-$(uname -r)|linux-image-generic" | \
  head -n -2 | \
  sed 's/^linux-image-\(.*\)$/\1/' | \
  while read n
  do
    echo 'Purging unneeded kernel images and headers for: '$n
    sudo apt-get --yes purge linux-image-$n    #purge images
    sudo apt-get --yes purge linux-headers-$n  #purge headers
  done

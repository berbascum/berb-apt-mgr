#!/bin/bash

echo "Updating main bdm script"
cat berb-apt-mgr-bin-main.sh > pkg_rootfs/usr/bin/berb-apt-mgr

echo "Updating etc config files"
cp conf/* pkg_rootfs/etc/berb-apt-mgr/

echo "Updating conf_templates"
cp conf_templates/* pkg_rootfs/usr/share/berb-apt-mgr/

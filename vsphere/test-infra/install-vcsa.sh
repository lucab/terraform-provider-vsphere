#!/bin/bash
set -e

if [ $OVFTOOL_URL == "" ]; then
  echo "Please provide OVFTOOL_URL"
  exit 1
fi
if [ $VCSA_ISO_URL == "" ]; then
  echo "Please provide VCSA_ISO_URL"
  exit 1
fi
if [ $VCSA_TPL_PATH == "" ]; then
  echo "Please provide VCSA_TPL_PATH"
  exit 1
fi

# Install ovftool
curl ${OVFTOOL_URL} -o ./vmware-ovftool.bundle
chmod a+x ./vmware-ovftool.bundle
TERM=dumb sudo ./vmware-ovftool.bundle --eulas-agreed

# Install vCenter Server Appliance
curl ${VCSA_ISO_URL} -o ./vmware-vcenter.iso
sudo mkdir /mnt/vcenter
sudo mount -o loop ./vmware-vcenter.iso /mnt/vcenter
sudo /mnt/vcenter/vcsa-cli-installer/lin64/vcsa-deploy install --accept-eula ${VCSA_TPL_PATH}
sudo umount /mnt/vcenter

#!/bin/bash

PACKAGES="vim htop"

echo "Updating System"
yum update -y

echo "Finished update, installing EPEL"
yum install epel-release -y

echo "Installing custom packages"
yum --enablerepo=epel install $PACKAGES -y

echo "Removing EPEL and cleaning up"
yum remove epel-release -y
yum remove gcc kernel-devel kernel-headers dkms make bzip2 -y
yum autoremove -y

#!/bin/bash

PACKAGES="vim htop"

echo "Updating System"
yum update -y

echo "Finished update, installing EPEL"
cd /tmp/
curl -O http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm
rpm -ivh epel-release-7-8.noarch.rpm

echo "Installing custom packages"
yum --enablerepo=epel install $PACKAGES -y

echo "Removing EPEL and cleaning up"
yum remove epel-release -y
yum remove gcc kernel-devel kernel-headers dkms make bzip2 perl -y
package-cleanup --quiet --leaves --exclude-bin | xargs yum remove -y

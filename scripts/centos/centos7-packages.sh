#!/bin/bash

# Reference:
# https://wiki.centos.org/HowTos/Virtualization/VirtualBox/CentOSguest

yum install epel-release -y
yum clean all
yum groupinstall "Development Tools" -y
yum install kernel-devel -y
reboot

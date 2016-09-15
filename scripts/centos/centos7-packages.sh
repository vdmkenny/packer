#!/bin/bash

yum update -y
#yum update kernel* -y
yum install epel-release -y
yum install bzip2 dkms make gcc kernel-devel kernel-headers policycoreutils-python -y
reboot

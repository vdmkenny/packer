#!/usr/vin/env bash

wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb
dpkg -i puppetlabs-release-precise.deb
apt-get clean
rm -fR /var/lib/apt/lists/*
apt-get clean
apt-get update

# Client
sudo apt-get install puppet -y

# Ppa dependency
sudo apt-get install python-software-properties -y

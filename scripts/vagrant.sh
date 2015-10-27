#!/usr/vin/env bash

mkdir /home/vagrant/.ssh
echo 'vagrant  ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
wget --no-check-certificate -O authorized_keys 'https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub'
mv authorized_keys /home/vagrant/.ssh/
chown -R vagrant:vagrant /home/vagrant/.ssh
chmod -R go-rwsx /home/vagrant/.ssh

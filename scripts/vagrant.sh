#!/usr/vin/env bash

mkdir /home/vagrant/.ssh
curl -O -s 'https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub'
mv vagrant.pub /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh
chmod -R go-rwsx /home/vagrant/.ssh


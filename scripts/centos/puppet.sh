#!/usr/vin/env bash

rpm -ivh https://yum.puppetlabs.com/el/6.5/products/x86_64/puppetlabs-release-6-10.noarch.rpm
sudo yum clean all
sudo yum makecache

# Client
sudo yum install puppet -y


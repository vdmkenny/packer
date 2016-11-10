#!/usr/vin/env bash

#rpm -ivh https://yum.puppetlabs.com/el/6.5/products/x86_64/puppetlabs-release-6-10.noarch.rpm
rpm -ivh https://yum.puppetlabs.com/el/7/products/x86_64/puppetlabs-release-7-12.noarch.rpm
sudo yum clean all

# Client
sudo yum install puppet -y


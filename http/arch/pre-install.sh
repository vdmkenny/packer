#!/usr/bin/env bash

vagrant_passwd='vagrant'

/usr/bin/useradd -d /home/vagrant -G wheel -m vagrant
echo "vagrant:$vagrant_passwd" | chpasswd
cat > /etc/sudoers.d/10_vagrant << EOF
Defaults:vagrant !requiretty
  vagrant ALL=(ALL) NOPASSWD: ALL
EOF
systemctl start sshd

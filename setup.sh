#!/bin/bash
# abort this script when a command fails or a unset variable is used.
set -eu
# echo all the executed commands.
set -x

# let our user use root permissions without sudo asking for a password (because
# d-i adds us into the sudo group, but we must be on the admin group instead).
# alternatively: echo 'vagrant ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/vagrant
#groupadd -r admin
#usermod -a -G admin vagrant
gpasswd -d vagrant sudo
#sed -i -e 's,%admin ALL=(ALL) ALL,%admin ALL=(ALL) NOPASSWD:ALL,g' /etc/sudoers
#sed -i 's/^\(Defaults.*requiretty\)/#\1/' /etc/sudoers

# Add vagrant user to sudoers.
echo "vagrant        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

# Disable daily apt unattended updates.
echo 'APT::Periodic::Enable "0";' >> /etc/apt/apt.conf.d/10periodic

# installing the vagrant public key.
# NB vagrant will replace it on the first run.
install -d -m 700 /home/vagrant/.ssh
pushd /home/vagrant/.ssh
wget --no-check-certificate https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -O authorized_keys
chmod 600 ~/.ssh/authorized_keys
chown -R vagrant:vagrant .

# install the VirtualBox Guest Additions.
# this will be installed at /opt/VBoxGuestAdditions-VERSION.
# REMOVE_INSTALLATION_DIR=0 is to fix a bug in VBoxLinuxAdditions.run.
# See http://stackoverflow.com/a/25943638.
apt-get -y -q install gcc dkms
mkdir -p /mnt
mount -o ro /dev/sr1 /mnt
while [ ! -f /mnt/VBoxLinuxAdditions.run ]; do sleep 1; done
set +eu
REMOVE_INSTALLATION_DIR=0 /mnt/VBoxLinuxAdditions.run --target /tmp/VBoxGuestAdditions
set -eu
rm -rf /tmp/VBoxGuestAdditions
umount /mnt

# disable the DNS reverse lookup on the SSH server. this stops it from
# trying to resolve the client IP address into a DNS domain name, which
# is kinda slow and does not normally work when running inside VB.
echo UseDNS no >> /etc/ssh/sshd_config

# disable the graphical terminal. its kinda slow and useless on a VM.
sed -i -E 's,#(GRUB_TERMINAL\s*=).*,\1console,g' /etc/default/grub
update-grub

# use the up/down arrows to navigate the bash history.
# NB to get these codes, press ctrl+v then the key combination you want.
cat<<"EOF">>/etc/inputrc
"\e[A": history-search-backward
"\e[B": history-search-forward
set show-all-if-ambiguous on
set completion-ignore-case on
EOF

# clean packages.
apt-get -y autoremove
apt-get -y clean

# zero the free disk space -- for better compression of the box file.
#dd if=/dev/zero of=/EMPTY bs=1M ; rm -f /EMPTY
#! /bin/bash

source ./settings_upi.env

cat > rhel8-rt-worker-ks.cfg <<EOT
lang en_US
keyboard us
timezone America/New_York --isUtc
# This should be removed for production
rootpw --plaintext ${ROOT_PASSWORD}
#platform x86, AMD64, or Intel EM64T
reboot
text
url --url=${RHEL_BASEOS_LOCATION}
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
ignoredisk --only-use=${RHEL_INSTALL_DEV}
zerombr
clearpart --all --initlabel
autopart
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled
skipx
firstboot --disable
sshkey --username=core "${SSH_KEY}"
%post --interpreter=/bin/bash

# enable passwordless sudo for wheel
echo "%wheel   ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/wheel
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers


curl -s ${PXE_WEB_SERVER}/rhel8rt-scripts.sh | bash /dev/stdin enable_proxy
%end
%packages
@standard
%end
repo --name=appstream --baseurl=${RHEL_APPSTREAM_LOCATION}

EOT
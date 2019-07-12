#! /bin/bash

source ./scripts/settings_upi.env

cat > rhel8-worker-ks.cfg <<EOT
lang en_US
keyboard us
timezone America/New_York --isUtc
rootpw ${ROOT_PASSWORD} --plaintext
#platform x86, AMD64, or Intel EM64T
reboot
url --url=${RHEL_BASEOS_LOCATION}
bootloader --location=mbr --boot-drive=${RHEL_INSTALL_DEV} --append="rhgb quiet crashkernel=auto"
ignoredisk --only-use=${RHEL_INSTALL_DEV}
zerombr
clearpart --all --initlabel
autopart
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
user --name=core --name="CoreOS" --groups=wheel --password=${ROOT_PASSWORD} --plaintext

##### START POST-INSTALL  ###################################
%post --interpreter=/bin/bash --erroronfail --log=/root/ks-post.log
set -eux
# enable passwordless sudo for wheel
echo "%wheel   ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/wheel
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

# Get OCP Node Customizatons
curl -s ${KS_POST_SCRIPT} | bash /dev/stdin ${KS_POST_SCRIPT_OPTIONS}
%end
###### END POST-INSTALL   ###################################

%packages
@standard
-fprintd-pam
-nmap-ncat
-plymouth
-tcpdump
-wget
-cockpit
-dos2unix
-mailcap
-man-pages
-mlocate
-mtr
-nano
-realmd
-usbutils
-words
-insights-client
%end

repo --name=appstream --baseurl=${RHEL_APPSTREAM_LOCATION}
repo --name=rhel8rt --baseurl=${RHEL_RT_LOCATION}

EOT

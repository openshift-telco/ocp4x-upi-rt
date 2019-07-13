#! /bin/bash

source ./scripts/settings_upi.env

# For customization see the Kickstart reference:
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/performing_an_advanced_rhel_installation/index#kickstart_references

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
# Note: Create manual partitions!!!
# WARNING: using "autopart" creates a "swap" partition causing Kubelet to fail to start
part / --fstype xfs --grow
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
user --name=core --groups=wheel --password=${ROOT_PASSWORD} --plaintext

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
tree
jq
%end

%addon com_redhat_kdump --disable
%end

repo --name=appstream --baseurl=${RHEL_APPSTREAM_LOCATION} --install --cost=1
repo --name=rhel8rt --baseurl=${RHEL_RT_LOCATION} --install --cost=1

EOT

echo "Done. Kickstart 'rhel8-worker-ks.cfg' generated. Upload to the web server."
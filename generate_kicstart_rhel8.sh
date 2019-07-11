#! /bin/bash

source ./settings_upi.env

ENC_ROOT_PASSSWORD = `python -c "import crypt; print(crypt.crypt('${ROOT_PASSWORD}', '\$1\$9zqQvtSY\$'))"`

cat > rhel8-rt-worker-ks.cfg <<EOT
lang en_US
keyboard us
timezone America/New_York --isUtc
rootpw ${ENC_ROOT_PASSWORD} --iscrypted
#platform x86, AMD64, or Intel EM64T
reboot
url --url=${RHEL_BASEOS_LOCATION}
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
ignoredisk --only-use=${RHEL_INSTALL_DEV}
zerombr
clearpart --all --initlabel
autopart
auth --passalgo=sha512 --useshadow
selinux --enforcing
firewall --enabled --ssh
skipx
firstboot --disable
sshkey --username=core "${SSH_KEY}"
%post --interpreter=/bin/bash
# Get OCP Node Customizatons
curl -s ${KS_POST_SCRIP} | bash /dev/stdin enable_proxy
%end
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

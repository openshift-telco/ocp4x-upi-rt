curl --header "Content-Type: application/json-patch+json" \
--request PATCH \
--data '[{"op": "add", "path": "/status/capacity/example.com~1foo", "value": "5"}]' \
http://k8s-master:8080/api/v1/nodes/k8s-node-1/status


rpm-ostree override replace <kernel>

https://dnf-plugins-core.readthedocs.io/en/latest/versionlock.html




rpm-ostree override replace <kernel>


#----
#!/bin/bash
subscription-manager repos --enable rhel-8-for-x86_64-rt-rpms
yum groupinstall -y RT

#----

/etc/default/grub. The GRUB_DEFAULT= points to the kernel image
grub2-mkconfig -o /boot/grub2/grub.cfg


kernel-rt
kernel-rt-core
kernel-rt-devel
kernel-rt-modules
kernel-rt-modules-extra
rt-setup
rt-tests
rteval
rteval-loads
tuned-profiles-realtime

#----


chcon system_u:object_r:httpd_sys_content_t:s0 

####################################
# Copy RHEL8 and RHEL8-RT into HTTP  directory
####################################

mkdir -pv /opt/nginx/html/rhel8
mkdir /tmp/rhel8
mount -o loop,ro /root/rhel-8.0-x86_64-dvd-2.iso /tmp/rhel8
cp -a /tmp/rhel8/. /opt/nginx/html/rhel8/
umount /tmp/rhel8
chcon -R system_u:object_r:httpd_sys_content_t:s0 /opt/nginx/html/rhel8/


mkdir -pv /opt/nginx/html/rhel8rt
mkdir /tmp/rhel8rt
mount -o loop,ro /root/rhel-8.0-x86_64-dvd-boot.iso /tmp/rhel8rt 
cp -a /tmp/rhel8rt/. /opt/nginx/html/rhel8rt/
umount /tmp/rhel8rt
chcon -R system_u:object_r:httpd_sys_content_t:s0 /opt/nginx/html/rhel8rt/

# Test content is reachable
curl http://198.18.100.1:8000/rhel8rt/GPL 


####################################
# Enable epel for python3 and pip3
####################################

yum --enablerepo=epel search pip 
yum install --enablerepo=epel python36-pip
pip3 install yq

####################################
# INSTALLING RT KERNEL 
####################################

yum install  http://198.18.100.1:8000/rhel8rt/Packages/kernel-rt-4.18.0-80.rt9.138.el8.x86_64.rpm \
http://198.18.100.1:8000/rhel8rt/Packages/kernel-rt-core-4.18.0-80.rt9.138.el8.x86_64.rpm \
http://198.18.100.1:8000/rhel8rt/Packages/kernel-rt-modules-4.18.0-80.rt9.138.el8.x86_64.rpm \
http://198.18.100.1:8000/rhel8rt/Packages/kernel-rt-modules-extra-4.18.0-80.rt9.138.el8.x86_64.rpm \
http://198.18.100.1:8000/rhel8rt/Packages/kernel-rt-devel-4.18.0-80.rt9.138.el8.x86_64.rpm \
http://198.18.100.1:8000/rhel8rt/Packages/rt-setup-2.0-10.el8.x86_64.rpm \
http://198.18.100.1:8000/rhel8rt/Packages/rt-tests-1.3-13.el8.x86_64.rpm \
http://198.18.100.1:8000/rhel8rt/Packages/tuned-profiles-realtime-2.10.0-15.el8.noarch.rpm
http://198.18.100.1:8000/rhel8rt/Packages/rteval-2.14-21.el8.noarch.rpm \
http://198.18.100.1:8000/rhel8rt/Packages/rteval-common-2.14-21.el8.noarch.rpm \
http://198.18.100.1:8000/rhel8rt/Packages/rteval-loads-1.4-3.el8.noarch.rpm \



systemctl reboot

rpm-ostree db diff


####-------

kernel-rt-4.18.0-80.rt9.138.el8.x86_64.rpm kernel-rt-core-4.18.0-80.rt9.138.el8.x86_64.rpm

kernel-rt-debug-4.18.0-80.rt9.138.el8.x86_64.rpm
kernel-rt-debug-core-4.18.0-80.rt9.138.el8.x86_64.rpm
kernel-rt-debug-devel-4.18.0-80.rt9.138.el8.x86_64.rpm
kernel-rt-debug-modules-4.18.0-80.rt9.138.el8.x86_64.rpm
kernel-rt-debug-modules-extra-4.18.0-80.rt9.138.el8.x86_64.rpm
kernel-rt-devel-4.18.0-80.rt9.138.el8.x86_64.rpm

kernel-rt-modules-4.18.0-80.rt9.138.el8.x86_64.rpm
kernel-rt-modules-extra-4.18.0-80.rt9.138.el8.x86_64.rpm

rteval-2.14-21.el8.noarch.rpm
rteval-common-2.14-21.el8.noarch.rpm
rteval-loads-1.4-3.el8.noarch.rpm
rt-setup-2.0-10.el8.x86_64.rpm
rt-tests-1.3-13.el8.x86_64.rpm
TRANS.TBL
tuned-profiles-realtime-2.10.0-15.el8.noarch.rpm

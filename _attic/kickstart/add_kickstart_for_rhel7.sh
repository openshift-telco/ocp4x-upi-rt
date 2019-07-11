#! /bin/bash

source $HOME/settings_upi.env

IGNITION_ENDPOINT="https://api.${CLUSTER_NAME}.${BASE_DOMAIN}:22623/config/worker"
CORE_SSH_KEY=$(cat $HOME/.ssh/id_rsa.pub)
ENROLL_CENTOS_NODE=$(cat ./scripts/enroll_centos_node.sh)
PODMAN_SERVICE=$(cat ./scripts/podman_service.sh)
KUBECONFIG_FILE=$(cat $KUBECONFIG_PATH)

cat > rhel7-worker-kickstart.cfg <<EOT
lang en_US
keyboard us
timezone Etc/UTC --isUtc
rootpw --plaintext ${ROOT_PASSWORD}
reboot
cmdline
install
url --url=${RHEL_INSTALL_ENDPOINT}
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
part / --fstype ext4 --grow
auth --passalgo=sha512 --useshadow
selinux --disabled
services --enabled=iptables
skipx
firstboot --disable
user --name=core --groups=wheel
%post --erroronfail --log=/root/ks-post.log

# write env vars for subscription
cat <<EOF > /etc/profile.env
export RH_USERNAME="${RH_USERNAME}"
export RH_PASSWORD="${RH_PASSWORD}"
export RH_POOL="${RH_POOL}"
EOF

# Add core ssh key
mkdir -m0700 /home/core/.ssh
cat <<EOF > /home/core/.ssh/authorized_keys
${CORE_SSH_KEY}
EOF
chmod 0600 /home/core/.ssh/authorized_keys
chown -R core:core /home/core/.ssh
restorecon -R /home/core/.ssh

# enable passwordless sudo for wheel
echo "%wheel   ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/wheel
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

# write pull secret
cat <<EOF > /tmp/pull.json
${PULL_SECRET}
EOF

# write kubeconfig
mkdir -p /root/.kube
cat <<EOF > /root/.kube/config
${KUBECONFIG_FILE}
EOF

# write ignition endpoint
cat <<EOF > /tmp/ignition_endpoint
${IGNITION_ENDPOINT}
EOF

# write enroll script
cat <<'EOF' > /tmp/enroll_rhel7_node.sh
${ENROLL_CENTOS_NODE}
EOF

# write runignition script
cat <<'EOF' > /tmp/runignition.sh
${PODMAN_SERVICE}
EOF

chmod a+x /tmp/runignition.sh
touch /tmp/runonce

# execute enroll script
bash /tmp/enroll_rhel7_node.sh
%end
%packages
@base
%end
EOT

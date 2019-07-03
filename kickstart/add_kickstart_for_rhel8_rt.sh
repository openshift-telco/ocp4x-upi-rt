#! /bin/bash

source ./settings_upi.env

IGNITION_ENDPOINT="https://api.${CLUSTER_NAME}.${BASE_DOMAIN}:22623/config/worker"
CORE_SSH_KEY=$(cat $HOME/.ssh/id_rsa.pub)
ENROLL_CENTOS_NODE=$(cat ./scripts/enroll_rhel8_node.sh)
ADD_RT_SCRIPT=$(cat ./scripts/add_rhel8_rt_kernel.sh)
PODMAN_SERVICE=$(cat ./scripts/podman_service.sh)
KUBECONFIG_FILE=$(cat $KUBECONFIG_PATH)
CHECK_SET_PROXY=$(cat ./scripts/check_set_proxy.sh)

cat > rhel8-rt-worker-kickstart.cfg <<EOT
lang en_US
keyboard us
timezone Etc/UTC --isUtc
ignoredisk --only-use=${RHEL_INSTALL_DEV}
rootpw --plaintext ${ROOT_PASSWORD}
reboot
cmdline
install
url --url=${RHEL_INSTALL_ENDPOINT}/

repo --name="AppStream" --baseurl=${RHEL_INSTALL_ENDPOINT}/AppStream/
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
part / --fstype ext4 --grow
auth --passalgo=sha512 --useshadow
selinux --disabled
skipx
firstboot --disable
user --name=core --groups=wheel

%packages
@^Infrastructure Server
%end

%post --erroronfail --log=/root/ks-post.log
# write env vars for subscription
cat <<EOF > /etc/profile.env
export RH_USERNAME="${RH_USERNAME}"
export RH_PASSWORD="${RH_PASSWORD}"
export RH_POOL="${RH_POOL}"
EOF

# pre-stage proxy configuration for environment variables
cat <<EOF > /etc/environment
# HTTP_PROXY=${WORKER_HTTP_PROXY}
# http_proxy=${WORKER_HTTP_PROXY}
# HTTPS_PROXY=${WORKER_HTTPS_PROXY}
# https_proxy=${WORKER_HTTPS_PROXY}
# NO_PROXY=.svc,.cluster.local,.${CLUSTER_NAME}.${BASE_DOMAIN},${CLUSTER_NETWORK},${SERVICE_NETWORK}
# no_proxy=.svc,.cluster.local,.${CLUSTER_NAME}.${BASE_DOMAIN},${CLUSTER_NETWORK},${SERVICE_NETWORK}
EOF

# write check_set_proxy script
cat <<'EOF' > /tmp/check_set_proxy.sh
${CHECK_SET_PROXY}
EOF

# run check_set_proxy to check for proxy config 
bash /tmp/check_set_proxy.sh

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
cat <<'EOF' > /tmp/enroll_rhel8_node.sh
${ENROLL_CENTOS_NODE}
EOF

# write rt script
cat <<'EOD' > /tmp/rt_script.sh
${ADD_RT_SCRIPT}
EOD

# write runignition script
cat <<'EOF' > /tmp/runignition.sh
${PODMAN_SERVICE}
EOF

chmod a+x /tmp/runignition.sh
touch /tmp/runonce

# execute enroll and rt script
bash /tmp/enroll_rhel8_node.sh
bash /tmp/rt_script.sh
%end

EOT

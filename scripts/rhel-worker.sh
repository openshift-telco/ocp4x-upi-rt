#! /bin/bash
##############################################################
# UPDATE TO MATCH YOUR ENVIRONMENT
##############################################################

SCRIPT_SERVER=http://198.18.100.1:8000/scripts

##############################################################
# DEFAULTS
##############################################################

SETTINGS_FILE=settings_upi.env

##############################################################
# DO NOT MODIFY AFTER THIS LINE
##############################################################
set -eux

RT_KERNEL=
KUBECONFIG_URL=

# Validate settings files exist
TEST_SETTINGS=`curl -s -o /dev/null -w "%{http_code}" ${SCRIPT_SERVER}/${SETTINGS_FILE}`

if [ "${TEST_SETTINGS}" -eq "200" ]; then
    echo "Great! Seetings file exist!";
    curl -s -J -L -o /tmp/${SETTINGS_FILE} ${SCRIPT_SERVER}/${SETTINGS_FILE}
    echo "Loading environment variables...";
    source /tmp/${SETTINGS_FILE}
else
    echo "ERROR: (Code: ${TEST_SETTINGS} ) Settings file ${SETTINGS_FILE} is not accessible. Check configuration of $0 script."
    exit 1
fi

usage() {
    echo -e "Usage: $0 [ -x | -r | -k <url-to-kubeconfig>] "
    echo -e "\t\t\t -x enable PROXY configuration\n\t\t\t -r enable real-time kernel\n\t\t\t -k URL to KUBECONFIG file"
}

set_proxy() {
    echo "Setting up PROXY environment configuration"
    cat <<EOF > /etc/environment
HTTP_PROXY=${WORKER_HTTP_PROXY}
http_proxy=${WORKER_HTTP_PROXY}
HTTPS_PROXY=${WORKER_HTTPS_PROXY}
https_proxy=${WORKER_HTTPS_PROXY}
NO_PROXY=.svc,.cluster.local,.${CLUSTER_NAME}.${BASE_DOMAIN},${CLUSTER_NETWORK},${SERVICE_NETWORK}
no_proxy=.svc,.cluster.local,.${CLUSTER_NAME}.${BASE_DOMAIN},${CLUSTER_NETWORK},${SERVICE_NETWORK}
EOF

    echo "Configure subscription-manager with PROXY configuration"
    subscription-manager config --server.proxy_hostname=${PROXY_HOST} --server.proxy_port=${PROXY_PORT}
}

enroll_and_install_node() {
    echo "Importing KEY from BaseOS repo"
    curl -s -o /tmp/RPM-GPG-KEY-redhat-release ${RHEL_BASEOS_LOCATION}/RPM-GPG-KEY-redhat-release
    rpm --import /tmp/RPM-GPG-KEY-redhat-release

    echo "Registering system"
    subscription-manager register --username $RH_USERNAME --password $RH_PASSWORD --force
    subscription-manager attach   --pool=$RH_POOL_OSP
    subscription-manager refresh

    # enable repos
    echo "Enabling RHEL and OCP repos"

    subscription-manager repos \
    --enable="rhel-8-for-x86_64-baseos-rpms" \
    --enable="rhel-8-for-x86_64-appstream-rpms" \
    --enable="rhel-8-for-x86_64-supplementary-rpms" \
    --enable="rhocp-4.1-for-rhel-8-x86_64-rpms"

    # install required packages
    echo "Upgrading OS"
    dnf update -y

    echo "Installing packages required for OCP"
    # dnf -y install git wget kernel irqbalance microcode_ctl systemd selinux-policy-targeted \
    # setools-console dracut-network passwd openssh-server openssh-clients podman skopeo runc \
    # containernetworking-plugins nfs-utils NetworkManager dnsmasq lvm2 iscsi-initiator-utils \
    # sg3_utils device-mapper-multipath xfsprogs e2fsprogs mdadm cryptsetup chrony logrotate \
    # sssd shadow-utils sudo coreutils less tar xz gzip bzip2 rsync tmux nmap-ncat net-tools \
    # bind-utils strace bash-completion vim-minimal nano authconfig iptables-services biosdevname \
    # cloud-utils-growpart glusterfs-fuse cri-o cri-tools openshift-clients openshift-hyperkube

    # Updated to match playbook. Not including duplicate packages.
    # https://github.com/openshift/openshift-ansible/blob/release-4.1/roles/openshift_node/defaults/main.yml
    dnf -y install cri-o openshift-clients openshift-hyperkube  \
    setools-console podman skopeo runc containernetworking-plugins cri-tools nfs-utils \
    dnsmasq iscsi-initiator-utils device-mapper-multipath tmux nmap-ncat  \
    authconfig iptables-services cloud-utils-growpart glusterfs-fuse
    # NOTE: Not available for RHEL8: policycoreutils-python container-storage-setup ceph-common bridge-utils 

    # enable cri-o
    systemctl enable cri-o

    # disable swap
    swapoff -a

    # enable ip forwarding
    sysctl -w net.ipv4.ip_forward=1
    sysctl --system

    # set sebool container_manage_cgroup to run systemd inside a container
    setsebool -P container_manage_cgroup on || true

    if [ -z "${RT_KERNEL}" ]; then
        echo "Regular RHEL Node"
    else
        echo "RHEL-RT Node. Installing Real-Time Kernel..."
        # NOTE: Commenting becaue using local repo
        subscription-manager attach --pool=$RH_POOL_RT
        subscription-manager repos --enable=rhel-8-for-x86_64-rt-rpms
        yum groupinstall -y RT
        set_rt_tuned_profile
    fi
}

set_rt_tuned_profile() {
    cat <<EOL > /etc/tuned/realtime-variables.conf
isolated_cores=2-39
hugepage_size_default=1G
hugepage_size=1G
hugepage_num=32
EOL

    cmdline_realtime="+isolcpus=\${isolated_cores} intel_pstate=disable nosoftlockup nmi_watchdog=0 audit=0 mce=off kthread_cpus=0 irqaffinity=0 skew_tick=1 processor.max_cstate=1 idle=poll intel_idle.max_cstate=0 intel_pstate=disable intel_iommu=off default_hugepagesz=\${hugepage_size_default} hugepagesz=\${hugepage_size} hugepages=\${hugepage_num} nohz=on nohz_full=\${isolated_cores} rcu_nocbs=\${isolated_cores}"

    sed -i 's|^cmdline_realtime.*|cmdline_realtime='"${cmdline_realtime}"'|' /usr/lib/tuned/realtime/tuned.conf  
    tuned-adm profile realtime

    echo "NOTICE: This node should be rebooted for Real-Time profile to take effect"
}

setup_ignition_service(){    
    cat <<EOL > /etc/systemd/system/runignition.service
[Unit]
Description=Run ignition commands
Requires=network-online.target
After=network-online.target crio.service

[Service]
ExecStart=/usr/local/bin/runignition.sh

[Install]
WantedBy=multi-user.target
EOL

    chmod 664 /etc/systemd/system/runignition.service
    systemctl daemon-reload 
    systemctl enable runignition

    sed -i '/^.*linux16.*/ s/$/ ip=${RHEL_PRIMARY_NIC}:dhcp rd.neednet=1/' /boot/grub2/grub.cfg

    curl -J -L -o /usr/local/bin/runignition.sh ${SCRIPT_SERVER}/runignition.sh
    chmod a+x /usr/local/bin/runignition.sh
    touch /tmp/runonce
}

set_kubeconfig() {
    if [ -z "${KUBECONFIG_URL}" ]; then
        echo "Extracting KUBECONFIG from MachineConfigPool..."
        mkdir /root/.kube 
        # NOTE: This requires python3. When using the script with Kickstart, explicitly define URL to kubeconfig
        curl -J -L -s ${SCRIPT_SERVER}/kubeconfig-from-ignition.py | /usr/libexec/platform-python /dev/stdin -f /tmp/bootstrap.ign -o /root/.kube/config -u ${IGNITION_URL}
    else
        echo "Retrieving KUBECONFIG from URL"
        mkdir /root/.kube 
        curl -k -J -L -s -o /root/.kube/config ${KUBECONFIG_URL}
    fi
}

add_sshkey_core() {
    # Add SSH Key to "root"
    mkdir -m0700 /root/.ssh
    echo ${SSH_KEY} >> /root/.ssh/authorized_keys
    chmod 0600 /root/.ssh/authorized_keys
    restorecon -R /root/.ssh

    # Add SSH Key to "core"
    mkdir -m0700 /home/core/.ssh
    echo ${SSH_KEY} >> /home/core/.ssh/authorized_keys
    chmod 0600 /home/core/.ssh/authorized_keys
    chown -R core:core /home/core/.ssh
    restorecon -R /home/core/.ssh
}

ssh_hardening() {
    # Disable root access 
    #sed -i '/^root/ s/\/bin\/bash/\/sbin\/nologin/' /etc/passwd
    # Enable passwordless sudo for wheel
    echo "%wheel   ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/wheel
    sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
    # SSH Hardening (only allow "core" user)
    echo "AllowUsers  core" >> /etc/ssh/sshd_config
    echo "DenyUsers   root" >> /etc/ssh/sshd_config
    echo "AllowGroups core" >> /etc/ssh/sshd_config
    echo "DenyUsers   root" >> /etc/ssh/sshd_config
    # Disable require TTY for sudo
    sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
}

##########################################
# Node Customizations
##########################################
# Read params
while getopts ":k:xrh" opt; do
    case ${opt} in
        k ) #kubeconfig
            KUBECONFIG_PATH=$OPTARG
            echo "Setting Kubeconfig URL: ${KUBECONFIG_PATH}"
            ;;
        x ) #set_proxy
            echo "Setting proxy"
            set_proxy
            ;;
        r ) #set rt kernel
            RT_KERNEL="enabled"
            echo "Setting Real-Time Kernel"
            ;;
        h )
            usage
            exit
            ;;
        \? )
            echo "Unknown param $OPTARG" 1>&2
            usage
            exit 1
            ;;
        : )
            echo "Invalid option: -$OPTARG requires an argument" 1>&2
            exit 1
            ;;
    esac
done

# Add SSH key to "core"
add_sshkey_core
ssh_hardening

# Write pull secret
printf ${PULL_SECRET} > /tmp/pull.json

# Pull ignition file into temporary file
curl -k -J -L -s -o /tmp/bootstrap.ign ${IGNITION_URL}

# Enroll NODE with RHN
# Add RT Kernel (if needed)
enroll_and_install_node

# Obtain Kubeconfig and setup Ignition Service
set_kubeconfig
setup_ignition_service

##############################################################
# END OF FILE
##############################################################
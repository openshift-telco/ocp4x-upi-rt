# Add RHEL/RHEL-RT 7.6 workers to OCP 4.x (PXE UPI)

The purpose of this repo is to describe the addition of RHEL and RHEL-RT nodes to an existing OCP 4.x bare-metal cluster using PXE Boot and UPI mode.

## TL;DR
1. Generate a `worker-rt` MachineConfigPool with the corresponding MachineConfigs as per instructions at [openshift4x-poc/rhel-rt/rhel-rt-mc-and-mcp.md](https://github.com/openshift-telco/openshift4x-poc/blob/master/rhel-rt/rhel-rt-mc-and-mcp.md)
2. Copy RHEL and RHEL-RT ISO content to web server
3. Update TFTP Boot and PXE Config
4. Update `./scripts/settings_up.env`
5. `./generate_kickstart_rhel7.sh`
6. `./upload.sh`
7. Boot node and select PXE install
8. Wait for ~20 mins for RHEL installation to complete. Approve CSR for SA. Approve CSR for Node.
   - `sleep 1200 ; ./approve-csr.sh ; sleep 20 ; ./approve-csr.sh`


## Setup Environment
- Generate a `worker-rt` MachineConfigPool with the corresponding MachineConfigs as per instructions at [openshift4x-poc/rhel-rt/rhel-rt-mc-and-mcp.md](https://github.com/openshift-telco/openshift4x-poc/blob/master/rhel-rt/rhel-rt-mc-and-mcp.md)


- Copy the content of RHEL7 ISO into HTTP directory

    ```
    mkdir -pv /opt/nginx/html/rhel7
    mkdir /tmp/rhel7
    mount -o loop,ro /root/rhel-server-7.6-x86_64-dvd.iso /tmp/rhel7 
    cp -a /tmp/rhel7/. /opt/nginx/html/rhel7/
    umount /tmp/rhel7
    chcon -R system_u:object_r:httpd_sys_content_t:s0 /opt/nginx/html/rhel7/
    ```
    Test content is reachable:

    ```
    curl http://198.18.100.1:8000/rhel7/GPL 

    # NOTE: Some configurations may require updating 
    # permissions to allow access to the content
    chmod -R 755 /opt/nginx/html/rhel7
    ```
- (Optional) If doing RHEL-RT: Copy the content of RHEL7-RT ISO into HTTP directory

    ```
    mkdir -pv /opt/nginx/html/rhel7rt
    mkdir /tmp/rhel7rt
    mount -o loop,ro /root/rhel-server-rt-7.6-x86_84-dvd.io /tmp/rhel7rt 
    cp -a /tmp/rhel7rt/. /opt/nginx/html/rhel7rt/
    umount /tmp/rhel7rt
    chcon -R system_u:object_r:httpd_sys_content_t:s0 /opt/nginx/html/rhel7rt/
    ```
    Test content is reachable:

    ```
    curl http://198.18.100.1:8000/rhel7rt/GPL 

    # NOTE: Some configurations may require updating 
    # permissions to allow access to the content
    chmod -R 755 /opt/nginx/html/rhel7rt
    ```

- Prepare RHEL PXE boot environment
    ```
    mkdir -pv /var/lib/tftpboot/rhel7
    cp /opt/nginx/html/rhel7/images/pxeboot/{vmlinuz,initrd.img} /var/lib/tftpboot/rhel7
    ```
    Update `/var/lib/tftpboot/pxelinux.cfg/default` with new entry pointing to the location for the Kickstart file

    ```
    LABEL WORKER-RHEL7
    MENU LABEL ^R RHEL7 WORKER (BIOS)
    KERNEL rhel7/vmlinuz
    APPEND rd.neednet=1 initrd=rhel7/initrd.img console=tty0 ip=dhcp inst.ks=http://198.18.100.1:8000/ks/rhel7-worker-ks.cfg
    ```

- Configure [`settings_upi.env`](scripts/settings_upi.env-UPDATETHIS) to match the environment. This should exist as `./scripts/settings_up.env`

- Generate Kickstart file for RHEL Nodes and update `SCRIPTS_URL=` in [`./scripts/rhel-worker.sh`](scripts/rhel-worker.sh) to match environment settings by executing:

    ```
    ./generate_kickstart_rhel7.sh
    ```
    NOTE: This will generate a `rhel7-worker-ks.cfg` and update `./scripts/rhel-worker.sh`

- (Option 1) When using the `openshift4x-poc` deployment and, if the `KUBECONFIG` environment variable is defined with absolute path, use the `upload.sh` script to copy the KUBECONFIG into the the scripts directory and upload the Kickstart and scripts configurations to the local web server. If it is not the case, use (Option 2).
    ```
    ./upload.sh
    ```
- (Option 2) Otherwise execute the corresponding manual steps:

  - Copy the content of KUBECONFIG file to `./scripts/kubeconfig`

  - Copy `rhel7-worker-ks.cfg` to the HTTP directory
      ```
      mkdir -pv /opt/nginx/html/ks
      cp ./rhel7-worker-ks.cfg /opt/nginx/html/ks
      ```

  - Copy `./scripts` folder to the HTTP directory

      ```
      cp -r ./scripts /opt/nginx/html
      ```

## Installation

- Boot the worker and wait for the install to complete. It may reboot twice during the installation.
  
- The OCP node installer will generate a CSR for the `node-bootstrapper` system ServiceAccount which need to be approved to continue the OCP installation. Few seconds after the first CSR is approved, it will send a system node CSRs which need to be approved. 
  
    - To monitor the CSR request use: `oc get csr`
    - To approve a CSR use: `oc adm certificate approve <cert-name>`

    TIP: If the OS installation and customization scripts take ~20 minutes (1200 seconds) and that is when the CSR are expected, the following sequence of commands can be used to wait 20 mins, retrieve Pending CSR and automatically approve them:

    ```
    sleep 1200 ; ./approve-csr.sh ; sleep 20 ; ./approve-csr.sh
    ```

# Credits
This work is based on original work by Yolanda Robla (Thanks!):
- [https://github.com/redhat-nfvpe/upi-rt](https://github.com/redhat-nfvpe/upi-rt)

Special thanks to:
- Puneet Marhatha
- Jay Cromer
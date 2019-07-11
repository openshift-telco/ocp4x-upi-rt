# Add real time kernel workers with OCP 4.x and UPI

The purpose of this repo is to describe the enroll of RHEL and RHEL-RT nodes on an existing OCP 4.x cluster based on baremetal (using UPI workflow)

## Introduction

- Copy the content of RHEL8 into HTTP directory

    ```
    mkdir -pv /opt/nginx/html/rhel8
    mkdir /tmp/rhel8
    mount -o loop,ro /root/rhel-8.0-x86_64-dvd.iso /tmp/rhel8
    cp -a /tmp/rhel8/. /opt/nginx/html/rhel8/
    umount /tmp/rhel8
    chcon -R system_u:object_r:httpd_sys_content_t:s0 /opt/nginx/html/rhel8/
    ```
    Test content is reachable

    ```
    curl http://198.18.100.1:8000/rhel8/GPL 
    ```


- (Optional: If doing RHEL-RT) Copy the content of RHEL8 into HTTP directory

    ```
    mkdir -pv /opt/nginx/html/rhel8rt
    mkdir /tmp/rhel8rt
    mount -o loop,ro /root/rhel-8.0-x86_64-dvd-rt.iso /tmp/rhel8rt 
    cp -a /tmp/rhel8rt/. /opt/nginx/html/rhel8rt/
    umount /tmp/rhel8rt
    chcon -R system_u:object_r:httpd_sys_content_t:s0 /opt/nginx/html/rhel8rt/
    ```
    Test content is reachable

    ```
    curl http://198.18.100.1:8000/rhel8rt/GPL 
    ```
- Prepare RHEL PXE boot environment
    ```
    mkdir -pv /var/lib/tftpboot/rhel8
    cp /opt/nginx/html/rhel8/images/pxeboot/{vmlinuz,initrd.img} /var/lib/tftpboot/rhel8
    ```
    Update `/var/lib/tftpboot/pxelinux.cfg/default`

    ```
    LABEL WORKER-RHEL
    MENU LABEL ^RHEL WORKER (BIOS)
    KERNEL rhel8/vmlinuz
    append initrd=rhel8/initrd.img ip=eth0:dhcp inst.repo=http://198.18.100.1:8000/rhel8/
    ```

- Configure [`settings_upi.env`](scripts/settings_upi.env-UPDATETHIS) to match the environment

- Update `SCRIPT_SERVER=` variable in script [`./scripts/rhel-worker.sh`](scripts/rhel-worker.sh) to point to the web server

- Copy `./scripts` folder to the HTTP directory

    ```
    cp -r ./scripts /opt/nginx/html
    ```
- Generate Kickstart file for RHEL Nodes.

    ```
    ./generate_kickstart_rhel8.sh
    ```
    This will generate a `rhel8-worker-ks.cfg`

- Copy `rhel8-worker-ks.cfg` to the HTTP directory
    ```
    cp ./rhel8-worker-ks.cfg /opt/nginx/html
    ```

- Update PXE boot and point to the Kickstart file in the web server
- Boot the worker and wait for the install to complete
- Accept node CSRs

# Credits
This is heavily based on original work by Yolanda Robla:
- [https://github.com/redhat-nfvpe/upi-rt](https://github.com/redhat-nfvpe/upi-rt)

Special thanks to:
- Puneet Marhatha
- Jay Cromer
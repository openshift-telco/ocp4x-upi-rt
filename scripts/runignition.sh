#!/bin/bash
set -eux

if [ -e /tmp/runonce ]; then
    rm /tmp/runonce

    # run release image
    echo "Running MCD"  > /root/runignition.log 2>&1
    oc version --config=/root/.kube/config >> root/runignition.log 2>&1

    CLUSTER_VERSION=$(oc get clusterversion --config=/root/.kube/config --output=jsonpath='{.items[0].status.desired.image}')
    podman pull --tls-verify=false --authfile /tmp/pull.json ${CLUSTER_VERSION}
    RELEASE_IMAGE=$(podman run --rm ${CLUSTER_VERSION} image machine-config-daemon)

    echo "Using CLUSTER_VERSION=${CLUSTER_VERSION}" >> /root/runignition.log 2>&1
    echo "Using RELEASE_IMAGE=${RELEASE_IMAGE}" >> /root/runignition.log 2>&1

    # run MCD image
    podman pull --tls-verify=false --authfile /tmp/pull.json ${RELEASE_IMAGE}  >> /root/runignition.log 2>&1
    podman run -v /:/rootfs -v /var/run/dbus:/var/run/dbus -v /run/systemd:/run/systemd --privileged --rm -ti ${RELEASE_IMAGE} start --node-name $HOSTNAME --once-from /tmp/bootstrap.ign --skip-reboot >> /root/runignition.log 2>&1

    echo "Running MCD completed!" >> /root/runignition.log 2>&1
    systemctl daemon-reload
    sleep 5 # inject delay before reboot
    reboot
fi

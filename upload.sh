#!/bin/sh

if [ -n ${KUBECONFIG} ]; do
    echo "Copying KUBECONFIG into scripts"
    cp -f ${KUBECONFIG} ./scripts/kubeconfig 
    echo "Uploading KS and scripts to local web server"
    cp -f -r ./scripts /opt/nginx/html
    cp -f ./rhel8-worker-ks.cfg /opt/nginx/html/ks
else
    echo "ERROR: Must define KUBECONFIG environment variable"
    exit 1
fi
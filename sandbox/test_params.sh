#!/bin/bash

KUBECONFIG_PATH=
RT_KERNEL=

usage() {
    echo -e "Usage: $0 [ -x | -r | -k <url-to-kubeconfig>] "
    echo -e "\t\t\t -x enable PROXY configuration\n\t\t\t -r enable real-time kernel\n\t\t\t -k URL to KUBECONFIG file"
}

set_proxy() {
    echo "running set_proxy"
}
add_rt_kernel() {
    echo "running add_rt_kernel"
}

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
            add_rt_kernel
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

echo "Done with options"
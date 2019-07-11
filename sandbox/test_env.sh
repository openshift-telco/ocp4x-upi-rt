#!/bin/bash

if [ ! -z "${DEBUG}" ]; then
	set -eux
fi

echo "This is a simple test script to validate configuration."
echo "Testing for KUBECONFIG environment variable..."

if [ -z "${KUBECONFIG}" ]; then
    echo "No KUBECONFIG found."
else
    echo "Found KUBECONFIG=${KUBECONFIG}"
fi
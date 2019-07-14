#!/bin/env bash

echo "Searching for Pending CSR requests..."
PENDING=`oc get csr | grep Pending`

if [ -z "${PENDING}"]; then
    echo -e "\tNo Pending CSRs found."
else
    echo -e "\tApproving Pending CSRs."
    oc get csr | grep Pending | cut -f 1 -d" " | oc adm certificate approve `xargs`
fi

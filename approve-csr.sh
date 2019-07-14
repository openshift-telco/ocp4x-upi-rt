#!/bin/env bash

echo "Searching for Pending CSR requests..."
PENDING_CSR=`oc get csr | grep Pending  | cut -f 1 -d" "`

if [ -z "${PENDING_CSR}"]; then
    echo -e "\tNo Pending CSRs found."
else
    echo -e "\tApproving Pending CSRs."
    oc adm certificate approve ${PENDING_CSR}
fi

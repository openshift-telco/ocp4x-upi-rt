#!/bin/bash
set -eux
# enable subscription
source ./settings_upi.env 

if [ -z "${WORKER_HTTP_PROXY}"]; then
    echo "No proxy. Yeaaaaah!"
else
    echo "Enabling PROXY ${WORKER_HTTP_PROXY}"
    # note: using "|" instead of "/" to correctly handle variables with "/"
    sed -i 's|#||g' /etc/environment
fi



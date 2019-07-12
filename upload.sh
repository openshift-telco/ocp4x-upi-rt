#!/bin/sh

echo "Uploading KS and scripts to local web server"
cp -f -r ./scripts /opt/nginx/html
cp -f ./rhel8-worker-ks.cfg /opt/nginx/html/ks


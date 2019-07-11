#!/usr/local/bin/python3

# For Linux use this
#!/bin/env python3

import argparse, json, urllib.request, urllib.parse, ssl 


parser = argparse.ArgumentParser(description='Extract Kubeconfig from Ignition.')
parser.add_argument('-f', '--file',  type=argparse.FileType('r'),
                help='read Ignition from file')
parser.add_argument('-u', '--url',
                help='read Ignition from URL (i.e. https://api.ocp4.example.com:22623/config/worker)',
                default='https://api.ocp4poc.lab.shift.zone:22623/config/worker')
parser.add_argument('-o', '--output', type=argparse.FileType('wt'),
                help='write retrieved Kubeconfig to file (default: /dev/stdout)',
                default='/dev/stdout')
args = parser.parse_args()

#default = 'https://api.ocp4poc.lab.shift.zone:22623/config/worker')


if args.file:
        print("# Retrieving Kubeconfig from FILE:", args.file.name)
        data = json.load(args.file)
else:
        print ("# Retrieving Kubeconfig from URL:", args.url)
        # Disable SSL certs validations for all URLS
        #ssl._create_default_https_context = ssl._create_unverified_context

        # Disable SSL cert validation for single URL
        ssl_context = ssl.create_default_context()
        ssl_context.check_hostname=False
        ssl_context.verify_mode=ssl.CERT_NONE 

        ignition = urllib.request.urlopen( args.url, context=ssl_context )
        data = json.loads(ignition.read().decode())

if data:
        for item in data['storage']['files']:
                if item['path'] == "/etc/kubernetes/kubeconfig":
                        encoded_s = item['contents']['source'].split(",")
                        encoded_s2 = encoded_s[1]
                        #print (urllib.parse.unquote(encoded_s2))
                        args.output.write(urllib.parse.unquote(encoded_s2))

#
# END OF FILE
#

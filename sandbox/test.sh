#!/bin/bash

if [[ "set_rt" =~ "${array[@]}" ]]; then
	echo "Found it!"
else
	echo "Not found: ${@}"
fi


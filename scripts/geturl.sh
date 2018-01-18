#!/bin/bash -e

# this is so you can test on phones

set -e

ADDRESS=$(ifconfig en0 | grep inet | grep broadcast | awk '{print $2}')

echo "http://$ADDRESS:3000"
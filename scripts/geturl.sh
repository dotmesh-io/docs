#!/bin/bash -e

set -e

ADDRESS=$(ifconfig en0 | grep inet | grep broadcast | awk '{print $2}')

echo "http://$ADDRESS:3000"
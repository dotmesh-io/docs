#!/bin/sh

METHOD="$1"
PARAMS="$2"
JSON="{\"jsonrpc\":\"2.0\",\"method\":\"$METHOD\",\"params\":$PARAMS,\"id\":6129484611666146000}"

echo "#### $METHOD."
echo ""
echo "##### Request."
echo ""
echo '```json'
echo "$JSON" | jq .
echo '```'
echo ""
echo "##### Response."
echo ""
echo '```json'

curl --user admin:`cat ~/.dotmesh/admin-password.txt` -H 'Content-Type: application/json' http://localhost:32607/rpc --data-binary "$JSON" 2>/dev/null | jq .

echo '```'

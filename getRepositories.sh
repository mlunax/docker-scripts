# modified version of https://github.com/kwk/docker-registry-setup#manual-token-based-workflow-to-list-repositories
#!/bin/bash

# This is the operation we want to perform on the registry
registryURL=$1/v2/_catalog

# Save the response headers of our first request to the registry to get the Www-Authenticate header
respHeader=/tmp/docker-script1.tmp.file;
curl -k --dump-header $respHeader $registryURL

# Extract the realm, the service, and the scope from the Www-Authenticate header
wwwAuth=$(cat $respHeader | grep "www-authenticate")
realm=$(echo $wwwAuth | grep -o '\(realm\)="[^"]*"' | cut -d '"' -f 2)
service=$(echo $wwwAuth | grep -o '\(service\)="[^"]*"' | cut -d '"' -f 2)
scope=$(echo $wwwAuth | grep -o '\(scope\)="[^"]*"' | cut -d '"' -f 2)

# Build the URL to query the auth server
authURL="$realm?service=$service&scope=$scope"
# Query the auth server to get a token

echo -n 'login: '
read -r login
echo -n 'pass: '
read -sr pass
echo

token=$(curl -ks -H "Authorization: Basic $(echo -n $login:$pass | base64)" "$authURL")

# Get the bare token from the JSON string: {"token": "...."}
token=$(echo $token | jq .access_token | tr -d '"')

# Query the registry again, but this time with a bearer token
curl -k -H "Authorization: Bearer $token" $registryURL

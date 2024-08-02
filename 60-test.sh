#!/usr/bin/env bash

set -eu

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source functions.sh
source set-env.sh


echo performing test

FQDN=$(./kubectl get gateway gateway-app -n $NAMESPACE -o jsonpath='{.status.addresses[0].value}')
echo FQDN: $FQDN

echo curling the application
curl $FQDN

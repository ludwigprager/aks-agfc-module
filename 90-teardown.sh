#!/usr/bin/env bash

set -eu

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/set-env.sh
source ${DIR}/functions.sh

set +e

echo deleting RG $RG_NAME
azcli az group delete --name ${RG_NAME} --yes

echo renaming kubeconfig
MY_RANDOM=$RANDOM
mv kubeconfig kubeconfig.${MY_RANDOM} 2> /dev/null

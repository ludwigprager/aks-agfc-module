#!/usr/bin/env bash

set -eu
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source functions.sh
source set-env.sh

# write the kubeconfig
azcli az aks get-credentials \
  --resource-group $RG_NAME \
  --name $AKS_NAME \
  --overwrite-existing

ALB_IDENTITY_CLIENT_ID=$(azcli az identity show -g $RG_NAME -n $ALB_IDENTITY --query clientId -o tsv)

# download local helm binary
install-helm

echo installing alb-controller helm chart
export KUBECONFIG=$BASEDIR/kubeconfig
./helm upgrade --install --wait alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller \
  --version 1.0.2 \
  --set albController.podIdentity.clientID=$ALB_IDENTITY_CLIENT_ID


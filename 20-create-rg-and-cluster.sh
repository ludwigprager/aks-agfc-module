#!/usr/bin/env bash

set -eu
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source functions.sh
source set-env.sh

# create resource group and AKS cluster with OIDC and Workload Identity enabled

if [ $(azcli az group exists --name $RG_NAME) == false ]; then
  echo "creating RG ${RG_NAME}"
  azcli az group create --name ${RG_NAME} --location ${LOCATION} -onone
else
  echo "RG ${RG_NAME} already exists"
fi

PORTAL_URL_PREFIX="https://portal.azure.com/#@$(get-tenant)/resource/subscriptions/$(get-subscription-id)/resourceGroups/${RG_NAME}"
echo "portal: $PORTAL_URL_PREFIX/overview"

if ! aks-cluster-exists ${RG_NAME} ${AKS_NAME}; then

  echo "creating AKS ${AKS_NAME}"
  azcli az aks create -g ${RG_NAME} -n ${AKS_NAME} \
    --location ${LOCATION} \
    --network-plugin azure \
    --node-count 1 \
    --enable-oidc-issuer \
    --enable-workload-identity \
    --generate-ssh-keys \
    -o none

else
  echo "AKS ${AKS_NAME} already exists"
fi

echo "portal: https://portal.azure.com/#browse/Microsoft.ContainerService%2FmanagedClusters"

# create kubeconfig
export KUBECONFIG=$BASEDIR/kubeconfig
azcli az aks get-credentials \
  --resource-group $RG_NAME \
  --name $AKS_NAME \
  --overwrite-existing


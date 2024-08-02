#!/usr/bin/env bash

set -eu
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $BASEDIR

source ./functions.sh
source ./set-env.sh

PORTAL_URL_PREFIX="https://portal.azure.com/#@$(get-tenant)/resource/subscriptions/$(get-subscription-id)/resourceGroups/${RG_NAME}"

echo
echo "resource group::        $PORTAL_URL_PREFIX/overview"
echo
echo "AKS cluster:            $PORTAL_URL_PREFIX/providers/Microsoft.ContainerService/managedClusters/aks-cluster/overview"
echo
echo "Federated Credential:   $PORTAL_URL_PREFIX/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${ALB_IDENTITY}/federatedcredentials"
echo
echo "AGFC:                   $PORTAL_URL_PREFIX/providers/Microsoft.ServiceNetworking/trafficControllers/${AGFC_NAME}/resourceOverviewId"
echo
echo "Frontend app:           $PORTAL_URL_PREFIX/providers/Microsoft.ServiceNetworking/trafficControllers/${AGFC_NAME}/frontends/frontend-app/overview"
echo
echo "Association:            $PORTAL_URL_PREFIX/providers/Microsoft.ServiceNetworking/trafficControllers/${AGFC_NAME}/associations"


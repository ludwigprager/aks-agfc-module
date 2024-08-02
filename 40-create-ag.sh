#!/usr/bin/env bash

set -eu

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source functions.sh
source set-env.sh

if ! alb-exists $RG_NAME $AGFC_NAME; then
  echo creating the AGFC resource
# azcli az network alb create -g $RG_NAME -n $AGFC_NAME -o none
  azcli az network alb create -g $RG_NAME -n $AGFC_NAME
else
  echo alb $AGFC_NAME already exists
fi

PORTAL_URL_PREFIX="https://portal.azure.com/#@$(get-tenant)/resource/subscriptions/$(get-subscription-id)/resourceGroups/${RG_NAME}"

echo "portal: $PORTAL_URL_PREFIX/providers/Microsoft.ServiceNetworking/trafficControllers/$AGFC_NAME/resourceOverviewId"

if ! alb-frontend-exists $RG_NAME $AGFC_FRONTEND_NAME $AGFC_NAME; then
  echo creating a frontend resource in the AGFC
  azcli az network alb frontend create -g $RG_NAME -n $AGFC_FRONTEND_NAME --alb-name $AGFC_NAME -o none
else
  echo alb frontend $AGFC_FRONTEND_NAME already exists
fi

echo "portal: $PORTAL_URL_PREFIX/providers/Microsoft.ServiceNetworking/trafficControllers/$AGFC_NAME/frontends/frontend-app/overview"


#!/usr/bin/env bash

set -eu
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source functions.sh
source set-env.sh

if ! identity-exists $RG_NAME $ALB_IDENTITY; then
  echo "creating ALB identity \'$ALB_IDENTITY\'"
  azcli az identity create \
    --resource-group $RG_NAME \
    --name $ALB_IDENTITY \
    -o none
  echo waiting 60s
  sleep 60
else
  echo identity $ALB_IDENTITY already exists
fi

PORTAL_URL_PREFIX="https://portal.azure.com/#@$(get-tenant)/resource/subscriptions/$(get-subscription-id)/resourceGroups/${RG_NAME}"
echo "portal: $PORTAL_URL_PREFIX/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${ALB_IDENTITY}/overview"

ALB_IDENTITY_PRINCIPAL_ID=$(azcli az identity show -g $RG_NAME -n $ALB_IDENTITY --query principalId -otsv)
MC_RG=$(azcli az aks show --name $AKS_NAME --resource-group $RG_NAME --query "nodeResourceGroup" -o tsv)
MC_RG_ID=$(azcli az group show --name $MC_RG --query id -otsv)

# Assign 'Reader' role to the AKS managed cluster resource group for the newly provisioned identity

echo creating role assignment: reader for ALB identity
azcli az role assignment create \
  --assignee-object-id $ALB_IDENTITY_PRINCIPAL_ID \
  --assignee-principal-type ServicePrincipal \
  --scope $MC_RG_ID \
  --role "acdd72a7-3385-48ef-bd42-f606fba81ae7" \
  -o none

# Set up federation with AKS OIDC issuer

AKS_OIDC_ISSUER="$(azcli az aks show -n $AKS_NAME -g $RG_NAME --query "oidcIssuerProfile.issuerUrl" -o tsv)"
# echo OIDC issuer: $AKS_OIDC_ISSUER

echo creating federated identity
azcli az identity federated-credential create --name "identity-azure-alb" \
  --identity-name $ALB_IDENTITY \
  --resource-group $RG_NAME \
  --issuer $AKS_OIDC_ISSUER \
  --subject "system:serviceaccount:azure-alb-system:alb-controller-sa" \
  -o none

SUBSCRIPTION_ID=$( get-subscription-id )
TENANT=$( get-tenant )
echo "portal:   $PORTAL_URL_PREFIX/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${ALB_IDENTITY}/federatedcredentials"


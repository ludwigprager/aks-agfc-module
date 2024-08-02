#!/usr/bin/env bash

set -eu

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source functions.sh
source set-env.sh

# ---

MC_RG=$(azcli az aks show --name $AKS_NAME --resource-group $RG_NAME --query "nodeResourceGroup" -o tsv)
CLUSTER_SUBNET_ID=$(azcli az vmss list --resource-group $MC_RG --query '[0].virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].subnet.id' -o tsv)

VNET_NAME=$(azcli az network vnet show --ids $CLUSTER_SUBNET_ID --query name -o tsv)
VNET_RG=$(azcli az network vnet show --ids $CLUSTER_SUBNET_ID --query resourceGroup -o tsv)
VNET_ID=$(azcli az network vnet show --ids $CLUSTER_SUBNET_ID --query id -o tsv)

echo creating subnet $VNET_NAME
azcli az network vnet subnet create \
  --resource-group $VNET_RG \
  --vnet-name $VNET_NAME \
  --name $AGFC_SUBNET_NAME \
  --address-prefixes $AGFC_SUBNET_PREFIX \
  --delegations "Microsoft.ServiceNetworking/trafficControllers" \
  -o none


ALB_SUBNET_ID=$(azcli az network vnet subnet show --name $AGFC_SUBNET_NAME --resource-group $VNET_RG --vnet-name $VNET_NAME --query '[id]' --output tsv)
ALB_IDENTITY_PRINCIPAL_ID=$(azcli az identity show -g $RG_NAME -n $ALB_IDENTITY --query principalId -otsv)
RG_ID=$(azcli az group show --name $RG_NAME --query id -otsv)

echo delegating permissions to managed identity
echo Delegating AGFC Configuration Manager role to AKS Managed Cluster RG
azcli az role assignment create --assignee-object-id $ALB_IDENTITY_PRINCIPAL_ID \
  --assignee-principal-type ServicePrincipal \
  --scope $RG_ID \
  --role "fbc52c3f-28ad-4303-a892-8a056630b8f1" \
  -o none

# Delegate Network Contributor permission for join to association subnet

echo delegating Network Contributor permission for join to association subnet
azcli az role assignment create --assignee-object-id $ALB_IDENTITY_PRINCIPAL_ID \
  --assignee-principal-type ServicePrincipal \
  --scope $ALB_SUBNET_ID \
  --role "4d97b98b-1d4f-4787-a291-c67834d212e7" \
  -o none

# Create the AppGw for Containers association and connect it to the referenced subnet

if ! alb-association-exists $RG_NAME $AGFC_ASSOCIATION $AGFC_NAME; then

  echo "creating the AppGw for Containers association and connecting"
  azcli az network alb association create -g $RG_NAME -n $AGFC_ASSOCIATION \
    --alb-name $AGFC_NAME \
    --subnet $ALB_SUBNET_ID \
    -o none

else

  echo AppGw for Containers association $AGFC_ASSOCIATION already exists

fi

PORTAL_URL_PREFIX="https://portal.azure.com/#@$(get-tenant)/resource/subscriptions/$(get-subscription-id)/resourceGroups/${RG_NAME}"
echo "portal $PORTAL_URL_PREFIX/providers/Microsoft.ServiceNetworking/trafficControllers/${AGFC_NAME}/associations"


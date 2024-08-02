#!/usr/bin/env bash

install-kubectl() {
  # install kubectl
  if [[ ! -f ./kubectl ]]; then
    #KUBECTL_VERSION=${1:-1.30.2}
    KUBECTL_VERSION=1.30.2
    echo downloading kubectl $KUBECTL_VERSION
    curl -LO https://dl.k8s.io/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl
    chmod +x kubectl
  fi
}

install-helm() {

  # install helm
  if [[ ! -f ./helm ]]; then
    HELM_VERSION=3.13.1 
    curl -LO https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz
    tar zxvf helm-v${HELM_VERSION}-linux-amd64.tar.gz
    mv linux-amd64/helm helm
    rm -rf linux-amd64
    rm helm-v${HELM_VERSION}-linux-amd64.tar.gz
    chmod +x helm
  fi

}

# from: https://stackoverflow.com/questions/53279143/getting-tenant-name-from-azure-cli
get-tenant() {
  # local name=$( azcli az account show | jq -r .tenantDisplayName )
  local name=$( azcli az rest --method get --url https://graph.microsoft.com/v1.0/domains --query 'value[?isDefault].id' -o tsv )
  if [[ ! -z ${name} ]]; then
    printf "${name}"
  fi
}
export -f get-tenant

get-subscription-id() {
  local subscription_id=$(azcli az account list -o json | jq -r .[].id)

  if [[ ! -z ${subscription_id} ]]; then
    printf "${subscription_id}"
  fi
}
export -f get-subscription-id

azcli() {
# local C_TOOL=docker
  local C_TOOL=podman
  local IMAGE=mcr.microsoft.com/azure-cli:2.61.0

  if [ $# -eq 0 ]; then
    COMMAND="/bin/bash"
  else
    COMMAND=$*
  fi

  ${C_TOOL} run \
    --rm \
    -w /work/ \
    -v $(pwd):/work/ \
    -v ${HOME}/.azure/:/.azure/ \
    -e AZURE_CONFIG_DIR='/.azure/' \
    -e KUBECONFIG=/work/kubeconfig \
    ${IMAGE} \
    ${COMMAND}
}
export -f azcli


get-identity-id-from-identity-name() {
  local resource_group=$1
  local identity_name=$2

  id=$(azcli az identity show \
    --resource-group ${resource_group} \
    --name ${identity_name} \
    --query 'clientId' -otsv)

  printf "$id"
}
export -f get-identity-id-from-identity-name

aks-cluster-exists() {
  local resource_group=$1
  local cluster_name=$2

  if azcli az aks show --name $cluster_name -g $resource_group > /dev/null 2>&1 ; then
    return 0 
  fi
  return 1
}
export -f aks-cluster-exists

identity-exists() {
  local resource_group=$1
  local identity_name=$2

  if azcli az identity  show --name $identity_name -g $resource_group > /dev/null 2>&1 ; then
    return 0 
  fi
  return 1
}
export -f identity-exists

federated-identity-exists() {
  local resource_group=$1
  local name=$2
  local identity_name=$3

  if azcli az identity  federated-credential show \
       --name $name \
       --identity-name $identity_name \
       -g $resource_group \
       > /dev/null 2>&1 ; then
    return 0 
  fi
  return 1
}
export -f federated-identity-exists

#keyvault-exists() {
#  local resource_group=$1
#  local keyvault_name=$2
#
#  if azcli az keyvault show --name $keyvault_name -g $resource_group > /dev/null; then
#    return 0 
#  fi
#  return 1
#}
#export -f keyvault-exists


alb-exists() {
  local resource_group=$1
  local name=$2
# local identity_name=$3

  if azcli az network alb show \
       --name $name \
       -g $resource_group \
       > /dev/null 2>&1 ; then
    return 0 
  fi
  return 1
}
export -f alb-exists

alb-frontend-exists() {
  local resource_group=$1
  local name=$2
  local alb_name=$3
# local identity_name=$3

  if azcli az network alb frontend show \
       --name $name \
       -g $resource_group \
       --alb-name $alb_name \
       > /dev/null 2>&1 ; then
    return 0 
  fi
  return 1
}
export -f alb-frontend-exists

alb-association-exists() {
  local resource_group=$1
  local name=$2
  local alb_name=$3

  if azcli az network alb association show \
       --name $name \
       -g $resource_group \
       --alb-name $alb_name \
       > /dev/null 2>&1 ; then
    return 0 
  fi
  return 1
}
export -f alb-association-exists


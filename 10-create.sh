#!/usr/bin/env bash

set -eu

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $BASEDIR

source functions.sh
source set-env.sh


#if [[ $# -eq 0 ]]; then
#  echo $0 "<subscription name>"
#  exit
#fi

#SUBSCRIPTION_NAME=$1

#./30-create-user-assigned-managed-identity.sh  $SUBSCRIPTION_NAME

./20-create-rg-and-cluster.sh
./30-create-managed-identity-for-alb-controller.sh
./35-install-alb-controller.sh
./40-create-ag.sh
./45-create-subnet-for-AG.sh
./50-deploy-gateway-and-application.sh
./60-test.sh


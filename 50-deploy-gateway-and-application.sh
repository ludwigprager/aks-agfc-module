#!/usr/bin/env bash

set -eu

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source functions.sh
source set-env.sh


# 6. Create Kubernetes Gateway resource

# Replace the $AGFC_ID and $AGFC_FRONTEND_NAME

AGFC_ID=$(azcli az network alb show --resource-group $RG_NAME --name $AGFC_NAME --query id -o tsv)
echo $AGFC_ID

install-kubectl

echo creating Gateway resource in namespace $NAMESPACE
cat << EOT | ./kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE

---

apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: gateway-app
  namespace: $NAMESPACE
  annotations:
    alb.networking.azure.io/alb-id: $AGFC_ID
spec:
  gatewayClassName: azure-alb-external
  listeners:
  - name: http-listener
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All # Same
  addresses:
  - type: alb.networking.azure.io/alb-frontend
    value: $AGFC_FRONTEND_NAME
EOT


# Once the gateway resource has been created, ensure the status is valid, the listener is Programmed, and an address is assigned to the gateway.

#./kubectl get gateway gateway-app -n $NAMESPACE -o yaml

#echo sleeping 60s for the gateway to be ready
#sleep 60 # wait for the gateway to be ready

#./kubectl get gateway gateway-app -n $NAMESPACE -o yaml

echo deploying application
cat << EOT | ./kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ns-app
---
apiVersion: v1
kind: Service
metadata:
  name: svc-app
  namespace: ns-app
spec:
  selector:
    app: deploy-app
  ports:
    - protocol: TCP
      port: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-app
  namespace: ns-app
  labels:
    app: deploy-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: deploy-app
  template:
    metadata:
      labels:
        app: deploy-app
    spec:
      containers:
      - name: aspnetapp
#       image: mcr.microsoft.com/dotnet/samples:aspnetapp
        image: nginx
        ports:
        - containerPort: 80
EOT


echo deploying HTTPRoute

cat << EOT | ./kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: httproute-app
  namespace: ns-app
spec:
  parentRefs:
  - kind: Gateway
    name: gateway-app
    namespace: $NAMESPACE
  rules:
  - backendRefs:
    - name: svc-app
      port: 80
EOT


#!/usr/bin/bash -euo pipefail

set -euo pipefail

AZ_RESOURCE_GROUP_NAME="myResourceGroup000"
AZ_LOCATION="eastus"
AZ_CONTAINER_GROUP_NAME="appcontainer"
AZ_CONTAINER_GROUP_IMAGE="mcr.microsoft.com/azuredocs/aci-helloworld"
AZ_VNET_NAME_CONTAINER_GROUP="myVNet"
AZ_SUBNET_NAME_VNET_CONTAINER_GROUP="myACISubnet"
AZ_SUBNET_NAME_VNET_APP_GATEWAY="myAGSubnet"
AZ_BACKEND_POOL_APP_GATEWAY_NAME="myAppGatewayBackendPool"
AZ_PUBLIC_IP_NAME_APP_GATEWAY="myAGPublicIPAddress"
AZ_APP_GATEWAY_NAME="myAppGateway"
# Connect-AzAccount
# Select-Azsubscription -SubscriptionName $AZ_SUBSCRIPTION_ID

# Based on 
# https://docs.microsoft.com/en-us/azure/container-instances/container-instances-application-gateway


az group create \
  --name ${AZ_RESOURCE_GROUP_NAME} \ 
  --location ${AZ_LOCATION}

az network vnet create \
  --name ${AZ_VNET_NAME_CONTAINER_GROUP} \
  --resource-group ${AZ_RESOURCE_GROUP_NAME} \
  --location ${AZ_LOCATION} \
  --address-prefix 10.0.0.0/16 \
  --subnet-name ${AZ_SUBNET_NAME_VNET_APP_GATEWAY} \
  --subnet-prefix 10.0.1.0/24

az network vnet subnet create \
  --name ${AZ_SUBNET_NAME_VNET_CONTAINER_GROUP} \
  --resource-group ${AZ_RESOURCE_GROUP_NAME} \
  --vnet-name ${AZ_VNET_NAME_CONTAINER_GROUP}   \
  --address-prefix 10.0.2.0/24

az network public-ip create \
  --resource-group ${AZ_RESOURCE_GROUP_NAME} \
  --name ${AZ_PUBLIC_IP_NAME_APP_GATEWAY} \
  --allocation-method Static \
  --sku Standard

az network application-gateway create \
  --name ${AZ_APP_GATEWAY_NAME} \
  --location ${AZ_LOCATION} \
  --resource-group ${AZ_RESOURCE_GROUP_NAME} \
  --capacity 2 \
  --sku Standard_v2 \
  --http-settings-protocol http \
  --public-ip-address ${AZ_PUBLIC_IP_NAME_APP_GATEWAY} \
  --vnet-name ${AZ_VNET_NAME_CONTAINER_GROUP} \
  --subnet ${AZ_SUBNET_NAME_VNET_APP_GATEWAY} 

az container create \
  --name ${AZ_CONTAINER_GROUP_NAME} \
  --resource-group ${AZ_RESOURCE_GROUP_NAME} \
  --image ${AZ_CONTAINER_GROUP_IMAGE} \
  --vnet ${AZ_VNET_NAME_CONTAINER_GROUP} \
  --subnet ${AZ_SUBNET_NAME_VNET_CONTAINER_GROUP}

az container show \
  --name ${AZ_CONTAINER_GROUP_NAME} \
  --resource-group ${AZ_RESOURCE_GROUP_NAME} \
  --query ipAddress.ip --output tsv

ACI_IP=$(az container show \
  --name ${AZ_CONTAINER_GROUP_NAME} \
  --resource-group ${AZ_RESOURCE_GROUP_NAME} \
  --query ipAddress.ip --output tsv)

az network application-gateway address-pool create \
  --gateway-name ${AZ_APP_GATEWAY_NAME} \
  --name ${AZ_BACKEND_POOL_APP_GATEWAY_NAME} \
  --resource-group ${AZ_RESOURCE_GROUP_NAME}\
  --servers "$ACI_IP" 

PUB_IP=$(az network public-ip show \
--resource-group ${AZ_RESOURCE_GROUP_NAME} \
--name ${AZ_PUBLIC_IP_NAME_APP_GATEWAY} \
--query [ipAddress] \
--output tsv)

curl $PUB_IP

echo $PUB_IP

echo "Go to azure portal and tweak accordingly the resources. Then download deployment of whole resource group, clean up, and ship it."
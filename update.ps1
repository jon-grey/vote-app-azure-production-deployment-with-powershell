Set-StrictMode -Version Latest

$AZ_SUBSCRIPTION_ID="53cda94b-af20-45ab-82c0-04e260445517"
$AZ_RESOURCE_GROUP_NAME="myResourceGroup"
$AZ_LOCATION="eastus"
$AZ_CONTAINER_GROUP_NAME="appcontainer"
$AZ_VNET_NAME_CONTAINER_GROUP="myVNet"
$AZ_SUBNET_NAME_VNET_CONTAINER_GROUP="myACISubnet"
$AZ_SUBNET_NAME_VNET_APP_GATEWAY="myAGSubnet"
$AZ_PUBLIC_IP_NAME_APP_GATEWAY="myAGPublicIPAddress"
$AZ_APP_GATEWAY_NAME="myAppGateway"
$AZ_BACKEND_POOL_APP_GATEWAY_NAME="myAppGatewayBackendPool"

# How to AZ QUERY: 
# https://docs.microsoft.com/en-us/cli/azure/query-azure-cli
# VERY NICE:
# pip install jmespath-terminal
# az vm list --output json | jpterm
# exit: F5, execute: <automatic>

# Official workaround about changing private ip of ACI allocated to APP GW Backend Pool
# https://github.com/MicrosoftDocs/azure-docs/issues/65128

# Stackoverflow NO SOLUTION: https://stackoverflow.com/questions/63780008/networking-between-container-groups-in-a-virtual-network-without-ip-addresses

# This works only for VMs - dont use it
# https://docs.microsoft.com/en-us/azure/dns/private-dns-autoregistration

# SDK
# https://docs.microsoft.com/en-us/cli/azure/network/application-gateway?view=azure-cli-latest
# https://docs.microsoft.com/en-us/cli/azure/network/application-gateway/address-pool?view=azure-cli-latest#az_network_application_gateway_address_pool_update


# Connect-AzAccount
# Select-Azsubscription -SubscriptionName $AZ_SUBSCRIPTION_ID

$AZ_PRIVATE_IP_CONTAINER_GROUP=(az container show `
  --name ${AZ_CONTAINER_GROUP_NAME} `
  --resource-group ${AZ_RESOURCE_GROUP_NAME} `
  --query ipAddress.ip --output tsv)

$AZ_APP_GATEWAY=(az network application-gateway show `
 --name ${AZ_APP_GATEWAY_NAME} `
 --resource-group ${AZ_RESOURCE_GROUP_NAME})

$AZ_BACKEND_POOL_APP_GATEWAY=(az network application-gateway address-pool show `
  --name ${AZ_BACKEND_POOL_APP_GATEWAY_NAME} `
  --gateway-name ${AZ_APP_GATEWAY_NAME} `
  --resource-group ${AZ_RESOURCE_GROUP_NAME})

$AZ_SERVERS_BACKEND_POOL_APP_GATEWAY=(az network application-gateway address-pool show `
  --name ${AZ_BACKEND_POOL_APP_GATEWAY_NAME} `
  --gateway-name ${AZ_APP_GATEWAY_NAME} `
  --resource-group ${AZ_RESOURCE_GROUP_NAME} `
  --query backendAddresses[].ipAddress `
  --output tsv)

$ACI_IP=(az container show `
  --name ${AZ_CONTAINER_GROUP_NAME} `
  --resource-group ${AZ_RESOURCE_GROUP_NAME} `
  --query ipAddress.ip --output tsv)

$STR="$AZ_SERVERS_BACKEND_POOL_APP_GATEWAY"
$SUB="$ACI_IP"

if ($STR -Match $SUB) {
  echo "ACI <$AZ_CONTAINER_GROUP_NAME> private ip ${ACI_IP} IS in APP GW Backend POOL ${AZ_BACKEND_POOL_APP_GATEWAY_NAME} list of 'servers' ${AZ_SERVERS_BACKEND_POOL_APP_GATEWAY}."
  echo "Abort."
} else {
  echo "ACI <$AZ_CONTAINER_GROUP_NAME> private ip ${ACI_IP} IS NOT in APP GW Backend POOL ${AZ_BACKEND_POOL_APP_GATEWAY_NAME} list of 'servers' ${AZ_SERVERS_BACKEND_POOL_APP_GATEWAY}"

  $BACKEND_POOL_UNHEALTHY_SERVERS=(az network application-gateway show-backend-health `
    --resource-group $AZ_RESOURCE_GROUP_NAME  `
    --name $AZ_APP_GATEWAY_NAME  `
    --query "backendAddressPools[].backendHttpSettingsCollection[].servers[?health=='Unhealthy'].address" `
    --output tsv)

  echo "Detected unhealthy servers addresses: ${BACKEND_POOL_UNHEALTHY_SERVERS}"

  # declare -A hashmap
  # hashmap[$ACI_IP]=1
  # for ip in $STR; do
  #   if [[ "$STR" != *"$BACKEND_POOL_UNHEALTHY_SERVERS"* ]]; then
  #     hashmap[$ip]=1
  #   fi
  # done

  echo "New backend pool servers will be: ${!hashmap[@]}"

  az network application-gateway address-pool update `
  --resource-group ${AZ_RESOURCE_GROUP_NAME} `
  --gateway-name ${AZ_APP_GATEWAY_NAME}  `
  --name ${AZ_BACKEND_POOL_APP_GATEWAY_NAME} `
  --servers ${!hashmap[@]}

  $AZ_SERVERS_BACKEND_POOL_APP_GATEWAY=(az network application-gateway address-pool show `
  --name ${AZ_BACKEND_POOL_APP_GATEWAY_NAME} `
  --gateway-name ${AZ_APP_GATEWAY_NAME} `
  --resource-group ${AZ_RESOURCE_GROUP_NAME} `
  --query backendAddresses[].ipAddress `
  --output tsv)

  echo "New backend pool servers updated to: ${AZ_SERVERS_BACKEND_POOL_APP_GATEWAY}"
}

$PUB_IP=(az network public-ip show `
--resource-group ${AZ_RESOURCE_GROUP_NAME} `
--name ${AZ_PUBLIC_IP_NAME_APP_GATEWAY} `
--query [ipAddress] `
--output tsv)

curl $PUB_IP

echo $PUB_IP
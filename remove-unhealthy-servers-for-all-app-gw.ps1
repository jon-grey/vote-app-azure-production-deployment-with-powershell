Set-StrictMode -Version Latest

$RESOURCE_GROUP_NAME="myResourceGroup"

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

Import-Module "Remove-Unhealthy-Servers-From-App-Gw-Backend-Pool.psm1";
Get-Command -Module "Remove-Unhealthy-Servers-From-App-Gw-Backend-Pool";


######################################################################################################################################
#### Loop over APP GWs
######################################################################################################################################
Get-AzApplicationGateway -ResourceGroupName ${RESOURCE_GROUP_NAME} | ForEach {

  $APP_GW = $_
  $APP_GW_NAME=$APP_GW.Name

  ######################################################################################################################################
  #### Get app gw backend pool health status of servers (container group)
  ######################################################################################################################################
  $BACKEND_POOLS_APP_GW=(Get-AzApplicationGatewayBackendHealth `
      -ResourceGroupName $RESOURCE_GROUP_NAME  `
      -Name $APP_GW_NAME
  ).BackendAddressPools

  ######################################################################################################################################
  #### Loop over APP GW Backend Pools
  ######################################################################################################################################
  $BACKEND_POOLS_APP_GW | ForEach {
    Fix-App-Gw-Backend-Pool($_, $APP_GW_NAME)
  }

  $PUBLIC_IP_NAME_APP_GW = ($APP_GW.FrontendIpConfigurations.PublicIPAddress.Id | split-path -leaf)

  $PUB_IP=(az network public-ip show  `
  --resource-group ${RESOURCE_GROUP_NAME} `
  --name ${PUBLIC_IP_NAME_APP_GW} `
  --query [ipAddress] `
  --output tsv)

  $PUB_IP_STATUS_CODE=(curl -s -o /dev/null -w "%{http_code}" $PUB_IP)

  echo ">>> Connected to APP GW $APP_GW_NAME public IP $PUB_IP with status code $PUB_IP_STATUS_CODE"
}



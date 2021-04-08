Set-StrictMode -Version Latest

$AZ_RESOURCE_GROUP_NAME="myResourceGroup"
$AZ_PUBLIC_IP_NAME_APP_GATEWAY="myAGPublicIPAddress"
$AZ_APP_GATEWAY_NAME="myAppGateway"

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


##############################################################################
#### Get app gw
##############################################################################
$AZ_APP_GATEWAY=(Get-AzApplicationGateway `
 -Name ${AZ_APP_GATEWAY_NAME}  `
 -ResourceGroupName ${AZ_RESOURCE_GROUP_NAME})

##############################################################################
#### Get app gw backend pool health status of servers (container group)
##############################################################################
$AZ_BACKEND_POOLS_APP_GATEWAY=(
  (
    Get-AzApplicationGatewayBackendHealth `
    -ResourceGroupName $AZ_RESOURCE_GROUP_NAME  `
    -Name $AZ_APP_GATEWAY_NAME
  ).BackendAddressPools
)

$AZ_BACKEND_POOLS_APP_GATEWAY | ForEach {
  $TMP = $_
  $POOL_NAME = $TMP.BackendAddressPool.Id | split-path -leaf

  echo ">>> Check if App GW backend pool ${POOL_NAME} has servers."
  $HAS_SERVERS=($TMP.BackendHttpSettingsCollection | Select-Object Servers)

  ##############################################################################
  #### Zero servers - Abort
  ##############################################################################
  if (-not $HAS_SERVERS.Servers){
    echo ">>> App GW backend pool ${POOL_NAME} do not have servers. Abort."

  ##############################################################################
  #### Has servers
  ##############################################################################
  } else {
    echo ">>> Get App GW backend pool ${POOL_NAME} list of servers."
    $SERVERS = $TMP.BackendHttpSettingsCollection.Servers | Select-Object Address,Health

    echo ">>> Check if App GW backend pool ${POOL_NAME} is healthy."
    $SERVERS_UNHEALTHY=($SERVERS | Where-Object {$_.Health -eq "Unhealthy"})
    $SERVERS_HEALTHY=($SERVERS | Where-Object {$_.Health -eq "Healthy"})

    ##############################################################################
    #### Zero servers unhealthy - Abort
    ##############################################################################
    if (-Not $SERVERS_UNHEALTHY ) {
      echo ">>> App GW backend pool servers are healthy."
      echo ">>> Abort."

      $SERVERS=(Get-AzApplicationGatewayBackendAddressPool `
      -Name $POOL_NAME `
      -ApplicationGateway $AZ_APP_GATEWAY)

    ##############################################################################
    #### All servers unhealthy - remove from backend pool
    ##############################################################################
    } elseif (-Not $SERVERS_HEALTHY ) {
      echo ">>> All of app GW backend pool servers are unhealthy. Set backend pool $POOL_NAME servers list to empty."

      $AZ_APP_GATEWAY =(Set-AzApplicationGatewayBackendAddressPool `
      -Name $POOL_NAME `
      -ApplicationGateway $AZ_APP_GATEWAY)

      $AZ_APP_GATEWAY =(Set-AzApplicationGateway `
      -ApplicationGateway $AZ_APP_GATEWAY)

      $EMPTY_SERVERS=(Get-AzApplicationGatewayBackendAddressPool `
      -Name $POOL_NAME `
      -ApplicationGateway $AZ_APP_GATEWAY)

    ##############################################################################
    #### Some servers unhealthy - remove some from backend pool
    ##############################################################################
    } else {

      $SERVERS_UNHEALTHY=$SERVERS_UNHEALTHY.Address
      $SERVERS_HEALTHY= $SERVERS_HEALTHY.Address
    
      echo ">>> Unhealthy APP GW backend pool servers detected: $SERVERS_UNHEALTHY "

      echo ">>> New backend pool servers will be: $SERVERS_HEALTHY"

      $AZ_APP_GATEWAY=(Set-AzApplicationGatewayBackendAddressPool `
      -Name $POOL_NAME `
      -ApplicationGateway $AZ_APP_GATEWAY `
      -BackendIPAddresses $SERVERS_HEALTHY)

      $AZ_APP_GATEWAY =(Set-AzApplicationGateway `
      -ApplicationGateway $AZ_APP_GATEWAY)

      $UPDATED_SERVERS=(Get-AzApplicationGatewayBackendAddressPool `
      -Name $POOL_NAME `
      -ApplicationGateway $AZ_APP_GATEWAY)

      echo ">>> New backend pool servers updated to: ${SERVERS_HEALTHY}"
    }

  }
}

$PUB_IP=(az network public-ip show `
--resource-group ${AZ_RESOURCE_GROUP_NAME} `
--name ${AZ_PUBLIC_IP_NAME_APP_GATEWAY} `
--query [ipAddress] `
--output tsv)

curl $PUB_IP

echo $PUB_IP

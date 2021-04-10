Set-StrictMode -Version Latest

. .env.ps1


echo '
# ===============================================================================
# Get App Gw Backend Pool Server Addresses and append private IP of ACI
# ==============================================================================='

# Print private IP of Container Group 
$ACG=(Get-AzContainerGroup `
  -Name ${ACI_NAME} `
  -ResourceGroupName ${ARG_NAME})
$ACG

# Get private IP of Container Group  
$ACI_IP=(Get-AzContainerGroup `
  -Name ${ACI_NAME} `
  -ResourceGroupName ${ARG_NAME}).IpAddress

echo $ACI_IP

do {
  echo "Waiting for AppGwJob to finish: "
  $AppGwJob
  Start-Sleep -Seconds 10
} while ($AppGwJob.State -Match 'Running')

$AppGw = Get-AzApplicationGateway -Name ${APP_GW_NAME}  -ResourceGroupName ${ARG_NAME}

$BackendPool = Get-AzApplicationGatewayBackendAddressPool -Name ${APP_GW_BACK_POOL_NAME} -ApplicationGateway $AppGw

$BackendPool.BackendAddresses += @{ IpAddress = $ACG.IpAddress }
$BackendPool

# Create Backend Pool in APP GW that will route to private IP of Container Group  
$AppGw = Set-AzApplicationGatewayBackendAddressPool -Name ${APP_GW_BACK_POOL_NAME} -ApplicationGateway $AppGw -BackendIPAddresses $BackendPool.BackendAddresses.IpAddress

# Update App Gw
$AppGw = Set-AzApplicationGateway -ApplicationGateway $AppGw

# # FIXME it may be required
# $AppGw = Get-AzApplicationGateway `
# -Name ${APP_GW_NAME} `
# -ResourceGroupName ${ARG_NAME}

# $FrontEndPort = Get-AzApplicationGatewayFrontendPort `
# -ApplicationGateway $AppGw

# $FrontEndIpConfig = Get-AzApplicationGatewayFrontendIPConfig `
# -ApplicationGateway $AppGw 

# $AppGw = Set-AzApplicationGatewayHttpListener `
# -ApplicationGateway $AppGw `
# -Name ${APP_GW_HTTP_LISTE_NAME} `
# -Protocol ${APP_GW_BACK_POOL_PROTO} `
# -FrontendPort $FrontEndPort `
# -FrontendIpConfiguration $FrontEndIpConfig `
# -HostName ${APP_GW_HTTP_LISTE_HOST_NAME}

# # $AppGw.HttpListeners += $CustomerListener
# $AppGw = Set-AzApplicationGateway -ApplicationGateway $AppGw

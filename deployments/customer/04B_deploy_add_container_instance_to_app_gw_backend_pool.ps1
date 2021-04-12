Set-StrictMode -Version Latest

. .env.ps1


echo '
# ===============================================================================
# Wait for App GW
# ==============================================================================='

# do {
#   echo "Waiting for AppGwJob to finish: "
#   $AppGwJob
#   Start-Sleep -Seconds 10
# } while ($AppGwJob.State -Match 'Running')

do {
  $AppGw = Get-AzApplicationGateway `
    -Name ${APP_GW_NAME} `
    -ResourceGroupName ${ARG_NAME} `
    -ErrorVariable notPresent `
    -ErrorAction SilentlyContinue

  if ($notPresent -or -not $AppGw) {
    echo "[$(date)] Waiting for AppGw to be present..."
    Start-Sleep -Seconds 10
  } else {
    break
  }
} while ($true)

do {
  $AppGw = Get-AzApplicationGateway `
    -Name ${APP_GW_NAME} `
    -ResourceGroupName ${ARG_NAME}

  if ($AppGw.ProvisioningState -notmatch "Succeeded" -or  $AppGw.OperationalState -notmatch "Running"){
    echo "[$(date)] Waiting for AppGw to have ProvisioningState $($AppGw.ProvisioningState)/Succeeded, OperationalState $($AppGw.OperationalState)/Running..."
    Start-Sleep -Seconds 10
  } else {
    break
  }
} while ($true)

echo '
# ===============================================================================
# Append private IP of ACI ${ACI_NAME} to App Gw Backend Pool 
# ==============================================================================='

$ACG=(Get-AzContainerGroup `
  -Name $CUSTOMER.ACI_NAME `
  -ResourceGroupName ${ARG_NAME})

$BackendPool = Get-AzApplicationGatewayBackendAddressPool `
  -Name $CUSTOMER.APP_GW_BACK_POOL_CUSTOMER_NAME `
  -ApplicationGateway $AppGw

$BackendPool.BackendAddresses += @{ IpAddress = $ACG.IpAddress }

$AppGw = Set-AzApplicationGatewayBackendAddressPool `
  -Name $CUSTOMER.APP_GW_BACK_POOL_CUSTOMER_NAME `
  -ApplicationGateway $AppGw `
  -BackendIPAddresses ( $BackendPool.BackendAddresses.IpAddress | Select-Object -Unique )

# Create Backend Pool in APP GW that will route to private IP of Container Group  

echo '
# ===============================================================================
# Update App Gw
# ==============================================================================='

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

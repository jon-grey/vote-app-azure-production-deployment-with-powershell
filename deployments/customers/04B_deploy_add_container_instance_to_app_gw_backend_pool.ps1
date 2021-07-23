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
    echo "[$(date)] Waiting for AppGw to have ProvisioningState [$($AppGw.ProvisioningState)==Succeeded], OperationalState [$($AppGw.OperationalState)==Running]..."
    Start-Sleep -Seconds 10
  } else {
    break
  }
} while ($true)

echo '
# ===============================================================================
# Append private IP of ACI containerinstance-dummy-app to App Gw Backend Pool 
# TODO verify that this IP is not in other BPool
# NOTE updating Backend Pool is much faster than Rules or Listeners
# ==============================================================================='
$ACG=(Get-AzContainerGroup -Name "containerinstance-dummy-001" -ResourceGroupName ${ARG_NAME})
$BackendPool = Get-AzApplicationGatewayBackendAddressPool `
  -Name "${APP_GW_BACK_POOL_BASIC_NAME}DummyApp" `
  -ApplicationGateway $AppGw

$BackendPool.BackendAddresses += @{ IpAddress = $ACG.IpAddress }
$AppGw = Set-AzApplicationGatewayBackendAddressPool `
 -Name "${APP_GW_BACK_POOL_BASIC_NAME}DummyApp" `
 -ApplicationGateway $AppGw `
 -BackendIPAddresses ( $BackendPool.BackendAddresses.IpAddress | Select-Object -Unique )

echo '
# ===============================================================================
# Append private IP of ACI containerinstance-dummy to App Gw Backend Pool 
# TODO verify that this IP is not in other BPool
# NOTE updating Backend Pool is much faster than Rules or Listeners
# ==============================================================================='
$ACG=(Get-AzContainerGroup -Name "containerinstance-dummy-000" -ResourceGroupName ${ARG_NAME})
$BackendPool = Get-AzApplicationGatewayBackendAddressPool `
 -Name "${APP_GW_BACK_POOL_BASIC_NAME}Dummy" `
 -ApplicationGateway $AppGw
$BackendPool.BackendAddresses += @{ IpAddress = $ACG.IpAddress }
$AppGw = Set-AzApplicationGatewayBackendAddressPool `
  -Name "${APP_GW_BACK_POOL_BASIC_NAME}Dummy" `
  -ApplicationGateway $AppGw `
  -BackendIPAddresses ( $BackendPool.BackendAddresses.IpAddress | Select-Object -Unique )

echo '
# ===============================================================================
# Clean list of Basic App Gw Backend Pool (should be empty or not?)
# NOTE updating Backend Pool is much faster than Rules or Listeners
# ==============================================================================='
$AppGw = Set-AzApplicationGatewayBackendAddressPool `
  -Name ${APP_GW_BACK_POOL_BASIC_NAME} `
  -ApplicationGateway $AppGw 
# Create Backend Pool in APP GW that will route to private IP of Container Group  

echo '
# ===============================================================================
# Update App Gw
# NOTE updating Backend Pool is much faster than Rules or Listeners
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

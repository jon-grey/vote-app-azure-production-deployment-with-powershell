Set-StrictMode -Version Latest

. .env.ps1


echo '
#################################################################################
#### Create App GW
#### Azure Application Gateway	1,000 per subscription	
#################################################################################'
echo '
# ===============================================================================
# Create App Gw IP Config associated to Vnet Subnet
# ===============================================================================
'

$VNet = Get-AzVirtualNetwork `
  -Name ${VNET_NAME} `
  -ResourceGroupName ${ARG_NAME}

$SubnetAppGw = Get-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_APP_GW_NAME} `
  -VirtualNetwork $VNet 

# Create App Gw IP Config
$GatewayIPConfigurations = New-AzApplicationGatewayIPConfiguration `
  -Name ${APP_GW_IP_CONF_NAME} `
  -Subnet $SubnetAppGw


echo '
# ===============================================================================
# Create App Gw Frontend for specific Public IP and Private IP
# Front-end IP configurations, 2,	1 public and 1 private
# Front-end ports	100
# ===============================================================================
'

$PublicIp = Get-AzPublicIpAddress `
  -ResourceGroupName ${ARG_NAME} `
  -Name ${PUB_IP_NAME} 

# Create App Gw Frontend Port
$FrontEndPort = New-AzApplicationGatewayFrontendPort `
  -Name ${APP_GW_FRONT_NAME} `
  -Port ${APP_GW_FRONT_PORT}

# Create App Gw Frontend Ip Config associated to Public IP
$FrontEndIpConfigPublic = New-AzApplicationGatewayFrontendIPConfig `
  -Name "appGwPublicFrontendIp" `
  -PublicIPAddress $PublicIp

# Create App Gw Frontend Ip Config associated to Public IP
$FrontEndIpConfigPrivate = New-AzApplicationGatewayFrontendIPConfig `
  -Name "appGwPrivateFrontendIp" `
  -PrivateIPAddress (Set-IpAddressOctet $SubnetAppGw.AddressPrefix 10) `
  -Subnet $SubnetAppGw

# TODO uncomment it and handle update properly
# $AppGw = Get-AzApplicationGateway `
# -Name ${APP_GW_NAME} `
# -ResourceGroupName ${ARG_NAME}

# $FrontEndPort = Get-AzApplicationGatewayFrontendPort `
# -ApplicationGateway $AppGw

# $FrontEndIpConfig = Get-AzApplicationGatewayFrontendIPConfig `
# -ApplicationGateway $AppGw 


echo "
# ===============================================================================
# Create App Gw HttpListener for specific customer subdomain
# require: FrontEndPort, FrontEndIpConfig
# ===============================================================================

HTTP listeners,	200,	Limited to 100 active listeners that are routing traffic. 
Active listeners = total number of listeners - listeners not active.
If a default configuration inside a routing rule is set to route traffic 
(for example, it has a listener, a backend pool, and HTTP settings) 
then that also counts as a listener.
"

$Listeners = @()

$BasicListener = New-AzApplicationGatewayHttpListener `
  -Name "${APP_GW_HTTP_LISTE_BASIC_NAME}" `
  -Protocol ${APP_GW_BACK_POOL_PROTO} `
  -FrontendPort $FrontEndPort `
  -FrontendIpConfiguration $FrontEndIpConfigPublic 

$DummyListener = New-AzApplicationGatewayHttpListener `
  -Name "${APP_GW_HTTP_LISTE_BASIC_NAME}Dummy" `
  -Protocol ${APP_GW_BACK_POOL_PROTO} `
  -FrontendPort $FrontEndPort `
  -FrontendIpConfiguration $FrontEndIpConfigPublic `
  -HostName ${DNS_ZONE_NAME}

$DummyAppListener = New-AzApplicationGatewayHttpListener `
  -Name "${APP_GW_HTTP_LISTE_BASIC_NAME}DummyApp" `
  -Protocol ${APP_GW_BACK_POOL_PROTO} `
  -FrontendPort $FrontEndPort `
  -FrontendIpConfiguration $FrontEndIpConfigPublic `
  -HostName "app.${DNS_ZONE_NAME}"

$CUSTOMERS_IDX.forEach({
  $CustomerId = $_
  $C = $CUSTOMERS_MAP[$CustomerId]

  echo "===== Add new CustomerListener for CustomerId: $CustomerId with Name $($C.APP_GW_HTTP_LISTE_CUSTOMER_NAME) and HostName $($C.APP_GW_HTTP_LISTE_HOST_NAME)"
  
  $CustomerListener = New-AzApplicationGatewayHttpListener `
    -FrontendPort $FrontEndPort `
    -FrontendIpConfiguration $FrontEndIpConfigPublic `
    -Protocol ${APP_GW_BACK_POOL_PROTO} `
    -Name $C.APP_GW_HTTP_LISTE_CUSTOMER_NAME `
    -HostName $C.APP_GW_HTTP_LISTE_HOST_NAME

  $CUSTOMERS_MAP[$CustomerId]['APP_GW_HTTP_LISTE_CUSTOMER'] = $CustomerListener
  $Listeners += $CustomerListener
})

$Listeners += $DummyAppListener 
$Listeners += $DummyListener 
$Listeners += $BasicListener 

# TODO uncomment it and handle update properly
# $AppGw.HttpListeners += $CustomerListener
# $AppGw = Set-AzApplicationGateway -ApplicationGateway $AppGw


echo '
# ===============================================================================
# Create App Gw Backend
# Back-end address pools,	100
# ==============================================================================='

$BackendPools = @()


# Create App Gw Backend Pool pointing to Customer ACG
$BasicBackendPool = New-AzApplicationGatewayBackendAddressPool `
  -Name ${APP_GW_BACK_POOL_BASIC_NAME}

$DummyBackendPool = New-AzApplicationGatewayBackendAddressPool `
  -Name "${APP_GW_BACK_POOL_BASIC_NAME}Dummy"

$DummyAppBackendPool = New-AzApplicationGatewayBackendAddressPool `
  -Name "${APP_GW_BACK_POOL_BASIC_NAME}DummyApp"

$CUSTOMERS_IDX.forEach({
  $CustomerId = $_
  $C = $CUSTOMERS_MAP[$CustomerId]

  echo "===== Add new CustomerListener for CustomerId: $CustomerId with Name $($C.APP_GW_HTTP_LISTE_CUSTOMER_NAME) and HostName $($C.APP_GW_HTTP_LISTE_HOST_NAME)"
  
  $CustomerBackendPool = New-AzApplicationGatewayBackendAddressPool `
    -Name $C.APP_GW_BACK_POOL_CUSTOMER_NAME

  $CUSTOMERS_MAP[$CustomerId]['APP_GW_BACK_POOL_CUSTOMER'] = $CustomerBackendPool
  $BackendPools += $CustomerBackendPool 
})

$BackendPools += $DummyAppBackendPool 
$BackendPools += $DummyBackendPool 
$BackendPools += $BasicBackendPool 
#$AppGw.BackendAddressPools += $CustomerBackendPool
#$AppGw = Set-AzApplicationGateway -ApplicationGateway $AppGw

echo '
# ===============================================================================
# Create App Gw Backend Http Settings
# Back-end HTTP settings,	100
# ==============================================================================='

$BackendSettings = @()

$BasicBackendSettings = New-AzApplicationGatewayBackendHttpSettings `
  -Name ${APP_GW_BACK_HTTP_SETS_BASIC_NAME} `
  -Port ${APP_GW_BACK_POOL_PORT} `
  -Protocol ${APP_GW_BACK_POOL_PROTO} `
  -CookieBasedAffinity "Disabled" 

$DummyBackendSettings = New-AzApplicationGatewayBackendHttpSettings `
  -Name "${APP_GW_BACK_HTTP_SETS_BASIC_NAME}Dummy" `
  -Port ${APP_GW_BACK_POOL_PORT} `
  -Protocol ${APP_GW_BACK_POOL_PROTO} `
  -CookieBasedAffinity "Disabled" `
  -HostName ${DNS_ZONE_NAME}

$DummyAppBackendSettings = New-AzApplicationGatewayBackendHttpSettings `
  -Name "${APP_GW_BACK_HTTP_SETS_BASIC_NAME}DummyApp" `
  -Port ${APP_GW_BACK_POOL_PORT} `
  -Protocol ${APP_GW_BACK_POOL_PROTO} `
  -CookieBasedAffinity "Disabled" `
  -HostName "app.${DNS_ZONE_NAME}"

$CustomersAppBackendSettings = New-AzApplicationGatewayBackendHttpSettings `
  -Name "${APP_GW_BACK_HTTP_SETS_CUSTOMERS_NAME}" `
  -Port ${APP_GW_BACK_POOL_PORT} `
  -Protocol ${APP_GW_BACK_POOL_PROTO} `
  -CookieBasedAffinity "Disabled" `
  -HostName "*.app.${DNS_ZONE_NAME}"

$BackendSettings += $CustomersAppBackendSettings
$BackendSettings += $DummyAppBackendSettings
$BackendSettings += $DummyBackendSettings
$BackendSettings += $BasicBackendSettings
# $BackendSettings = Get-AzApplicationGatewayBackendHttpSetting `
#   -Name ${APP_GW_BACK_HTTP_SETS_NAME} `
#   -ApplicationGateway $AppGw 

echo '
# ===============================================================================
# Create App Gw Routing Rule for specific customer subdomain
# require: Listener, BackendPool, BackendSettings
# ==============================================================================='

$Rules = @()

$BasicRule = New-AzApplicationGatewayRequestRoutingRule `
  -Name ${APP_GW_ROUTING_RULE_BASIC_NAME} `
  -RuleType Basic `
  -BackendHttpSettings $BasicBackendSettings `
  -HttpListener $BasicListener `
  -BackendAddressPool $BasicBackendPool

$DummyRule = New-AzApplicationGatewayRequestRoutingRule `
  -Name "${APP_GW_ROUTING_RULE_BASIC_NAME}Dummy" `
  -RuleType Basic `
  -BackendHttpSettings $DummyBackendSettings `
  -HttpListener $DummyListener `
  -BackendAddressPool $DummyBackendPool

$DummyAppRule = New-AzApplicationGatewayRequestRoutingRule `
  -Name "${APP_GW_ROUTING_RULE_BASIC_NAME}DummyApp" `
  -RuleType Basic `
  -BackendHttpSettings $DummyAppBackendSettings `
  -HttpListener $DummyAppListener `
  -BackendAddressPool $DummyAppBackendPool


$CUSTOMERS_IDX.forEach({
    $CustomerId = $_
    $C = $CUSTOMERS_MAP[$CustomerId]
  
    echo "===== Add new RequestRoutingRule for CustomerId: $CustomerId with Name $($C.APP_GW_ROUTING_RULE_CUSTOMER_NAME)"
    
    $CustomerAppRule = New-AzApplicationGatewayRequestRoutingRule `
      -Name $C.APP_GW_ROUTING_RULE_CUSTOMER_NAME `
      -RuleType Basic `
      -BackendHttpSettings $DummyAppBackendSettings `
      -HttpListener $C['APP_GW_HTTP_LISTE_CUSTOMER']  `
      -BackendAddressPool $C['APP_GW_BACK_POOL_CUSTOMER']
   
    $CUSTOMERS_MAP[$CustomerId]['APP_GW_ROUTING_RULE_CUSTOMER'] = $CustomerAppRule

    $Rules += $CustomerAppRule 
  })

$Rules += $DummyAppRule 
$Rules += $DummyRule 
$Rules += $BasicRule 
# $AppGw.RequestRoutingRules += $CustomerRule
# $AppGw = Set-AzApplicationGateway -ApplicationGateway $AppGw

echo '
# ===============================================================================
# Create App Gw Autoscaling Config
# ==============================================================================='
$AutoscaleConfig = New-AzApplicationGatewayAutoscaleConfiguration -MinCapacity 0 -MaxCapacity 3

echo '
# ===============================================================================
# Create App Gw Identity
# ==============================================================================='

$Identity=(az identity show --resource-group ${ARG_INTERNAL_NAME} --name ${AMI_NAME}) | ConvertFrom-Json

$AppGwIdentity = New-AzApplicationGatewayIdentity -UserAssignedIdentityId $Identity.Id

# Create App Gw Sku
# NOTE name has to be of some valid parameter type
# otherwise it will fail with error: 
# ... Application Gateway SKU name Standard_v2 is not valid for the SKU tier Standard

echo '
# ===============================================================================
# Create App Gw Sku
# NOTE: do not specify capacity when using autoscaling
# ==============================================================================='


$Sku = New-AzApplicationGatewaySku -Name $APP_GW_SKU_NAME -Tier $APP_GW_SKU_TIER # -Capacity 1

echo '
# ===============================================================================
# Create App Gw
# require: BackendPool, BackendSettings, FrontEndIpConfig, FrontEndPort, 
#          IpConfigAppGw, Listener, Rule, Sku
# ==============================================================================='


# Create App Gw
$AppGwJob = New-AzApplicationGateway `
  -Name ${APP_GW_NAME} `
  -Location ${LOCATION} `
  -ResourceGroupName ${ARG_NAME} `
  -FrontendPorts $FrontEndPort `
  -FrontendIpConfigurations @($FrontEndIpConfigPublic, $FrontEndIpConfigPrivate) `
  -AutoscaleConfiguration $AutoscaleConfig `
  -GatewayIpConfigurations $GatewayIPConfigurations `
  -BackendHttpSettingsCollection $BackendSettings `
  -BackendAddressPools  $BackendPools `
  -RequestRoutingRules  $Rules `
  -HttpListeners $Listeners `
  -Identity $AppGwIdentity `
  -Sku $Sku `
  -AsJob

Start-Sleep -Seconds 5

if ($AppGwJob.State -eq "Failed") {
  Write-Error "AzApplicationGateway async JOB failed. MSG: $($AppGwJob.ChildJobs[0].JobStateInfo.Reason.Message)"
} else {
  Write-Host "AzApplicationGateway async JOB started successfully: $(Receive-Job $AppGwJob)" -ForegroundColor Green 
}
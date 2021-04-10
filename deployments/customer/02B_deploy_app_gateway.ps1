Set-StrictMode -Version Latest

. .env.ps1


echo '
#################################################################################
#### Create App GW
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
# Create App Gw Frontend for specific Public IP
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
  -PrivateIPAddress (new-ipaddress $SubnetAppGw.AddressPrefix 10) `
  -Subnet $SubnetAppGw

# TODO uncomment it and handle update properly
# $AppGw = Get-AzApplicationGateway `
# -Name ${APP_GW_NAME} `
# -ResourceGroupName ${ARG_NAME}

# $FrontEndPort = Get-AzApplicationGatewayFrontendPort `
# -ApplicationGateway $AppGw

# $FrontEndIpConfig = Get-AzApplicationGatewayFrontendIPConfig `
# -ApplicationGateway $AppGw 

echo '
# ===============================================================================
# Create App Gw HttpListener for specific customer subdomain
# require: FrontEndPort, FrontEndIpConfig
# ==============================================================================='

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

$CustomerListener = New-AzApplicationGatewayHttpListener `
  -Name ${APP_GW_HTTP_LISTE_CUSTOMER_NAME} `
  -Protocol ${APP_GW_BACK_POOL_PROTO} `
  -FrontendPort $FrontEndPort `
  -FrontendIpConfiguration $FrontEndIpConfigPublic `
  -HostName ${APP_GW_HTTP_LISTE_HOST_NAME}

# TODO uncomment it and handle update properly
# $AppGw.HttpListeners += $CustomerListener
# $AppGw = Set-AzApplicationGateway -ApplicationGateway $AppGw


echo '
# ===============================================================================
# Create App Gw Backend
# ==============================================================================='

# Create App Gw Backend Pool pointing to Customer ACG
$BasicBackendPool = New-AzApplicationGatewayBackendAddressPool `
  -Name ${APP_GW_BACK_POOL_BASIC_NAME}

$DummyBackendPool = New-AzApplicationGatewayBackendAddressPool `
  -Name "${APP_GW_BACK_POOL_BASIC_NAME}Dummy"

$CustomerBackendPool = New-AzApplicationGatewayBackendAddressPool `
  -Name ${APP_GW_BACK_POOL_CUSTOMER_NAME}

# TODO uncomment it and handle update properly
#$AppGw.BackendAddressPools += $CustomerBackendPool
#$AppGw = Set-AzApplicationGateway -ApplicationGateway $AppGw

# Create App Gw Backend Http Settings

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

$CustomerBackendSettings = New-AzApplicationGatewayBackendHttpSettings `
  -Name ${APP_GW_BACK_HTTP_SETS_CUSTOMER_NAME} `
  -Port ${APP_GW_BACK_POOL_PORT} `
  -Protocol ${APP_GW_BACK_POOL_PROTO} `
  -CookieBasedAffinity "Disabled" `
  -HostName ${APP_GW_HTTP_LISTE_HOST_NAME}

# TODO uncomment it and handle update properly
# $BackendSettings = Get-AzApplicationGatewayBackendHttpSetting `
#   -Name ${APP_GW_BACK_HTTP_SETS_NAME} `
#   -ApplicationGateway $AppGw 

echo '
# ===============================================================================
# Create App Gw Routing Rule for specific customer subdomain
# require: Listener, BackendPool, BackendSettings
# ==============================================================================='

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

$CustomerRule = New-AzApplicationGatewayRequestRoutingRule `
  -Name ${APP_GW_ROUTING_RULE_CUSTOMER_NAME} `
  -RuleType Basic `
  -BackendHttpSettings $CustomerBackendSettings `
  -HttpListener $CustomerListener `
  -BackendAddressPool $CustomerBackendPool


# TODO uncomment it and handle update properly
# $AppGw.RequestRoutingRules += $CustomerRule
# $AppGw = Set-AzApplicationGateway -ApplicationGateway $AppGw

echo '
# ===============================================================================
# Create App Gw
# require: BackendPool, BackendSettings, FrontEndIpConfig, FrontEndPort, 
#          IpConfigAppGw, Listener, Rule, Sku
# ==============================================================================='

$Identity=(az identity show --resource-group ${ARG_NAME} --name ${AMI_NAME}) | ConvertFrom-Json

$AppGwIdentity = New-AzApplicationGatewayIdentity -UserAssignedIdentityId $Identity.Id

# Create App Gw Sku
# NOTE name has to be of some valid parameter type
# otherwise it will fail with error: 
# ... Application Gateway SKU name Standard_v2 is not valid for the SKU tier Standard

$Sku = New-AzApplicationGatewaySku -Name $APP_GW_SKU_NAME -Tier $APP_GW_SKU_TIER -Capacity ${APP_GW_SKU_CAP}

# Create App Gw
$AppGwJob = New-AzApplicationGateway `
  -Name ${APP_GW_NAME} `
  -Location ${LOCATION} `
  -ResourceGroupName ${ARG_NAME} `
  -GatewayIpConfigurations $GatewayIPConfigurations `
  -FrontendPorts $FrontEndPort `
  -FrontendIpConfigurations @($FrontEndIpConfigPublic, $FrontEndIpConfigPrivate) `
  -BackendHttpSettingsCollection  @($CustomerBackendSettings, $DummyBackendSettings, $BasicBackendSettings) `
  -BackendAddressPools  @($CustomerBackendPool, $DummyBackendPool, $BasicBackendPool) `
  -RequestRoutingRules  @($CustomerRule, $DummyRule, $BasicRule) `
  -HttpListeners  @($CustomerListener, $DummyListener, $BasicListener) `
  -Sku $Sku `
  -Identity $AppGwIdentity 
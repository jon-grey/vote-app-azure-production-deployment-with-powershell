Set-StrictMode -Version Latest

. .env.ps1

#################################################################################
#### Notebook
#################################################################################

# ctrl + f `IMPORTANT`
# ctrl + f 'TODO`
# ctrl + f `FIXME`

#################################################################################
#### Create Resource Group
#################################################################################

New-AzResourceGroup -Name ${ARG_NAME} -Location ${LOCATION}

#################################################################################
#### Create Public Ip
#################################################################################

# Create Public IP
$PublicIp = New-AzPublicIpAddress `
  -ResourceGroupName ${ARG_NAME} `
  -Name ${PUB_IP_NAME} `
  -Location ${LOCATION} `
  -AllocationMethod ${PUB_IP_ALLOCATION_METHOD} 

#################################################################################
#### Create DNS Zone
#################################################################################

# Create Dns Zone
New-AzDnsZone `
  -Name ${DNS_ZONE_NAME} `
  -ResourceGroupName ${ARG_NAME}

$DnsZone = (Get-AzDnsZone `
   -Name ${DNS_ZONE_NAME} `
   -ResourceGroupName ${ARG_NAME})

echo "[IMPORTANT] Update in Your domain provider ie. godaddy.com, the domain DNS settings with NS (skip dots at the suffix): ", $DnsZone.NameServers

# ns1-09.azure-dns.com
# ns2-09.azure-dns.net
# ns3-09.azure-dns.org
# ns4-09.azure-dns.info

# Create type A name * record set targeting Public IP
New-AzDnsRecordSet `
  -Name '*' `
  -RecordType A `
  -Ttl 3600 `
  -ZoneName ${DNS_ZONE_NAME} `
  -ResourceGroupName ${ARG_NAME} `
  -TargetResourceId $PublicIp.Id

#################################################################################
#### Create VNET
#################################################################################

$VNet = New-AzVirtualNetwork `
  -Name ${VNET_NAME} `
  -ResourceGroupName ${ARG_NAME} `
  -Location ${LOCATION} `
  -AddressPrefix 10.0.0.0/16 

# ===============================================================================
# Add new Subnet for ACI to VNet
# ===============================================================================

$VNet = Get-AzVirtualNetwork `
  -Name ${VNET_NAME} `
  -ResourceGroupName ${ARG_NAME}


# Create subnet config for App GW
Add-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_APP_GW_NAME} `
  -VirtualNetwork $VNet `
  -AddressPrefix 10.0.0.0/24 | Set-AzVirtualNetwork

# ===============================================================================
# Add new Subnet for ACI to VNet
# ===============================================================================

$VNet = Get-AzVirtualNetwork `
  -Name ${VNET_NAME} `
  -ResourceGroupName ${ARG_NAME}
# Create subnet config for customer ACG

Add-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_ACI_NAME} `
  -VirtualNetwork $VNet `
  -AddressPrefix 10.0.1.0/24 `
| Set-AzVirtualNetwork


#################################################################################
#### Create App GW
#################################################################################

# ===============================================================================
# Create App Gw Frontend for specific Public IP
# ===============================================================================

# Create App Gw Frontend Port
$FrontEndPort = New-AzApplicationGatewayFrontendPort `
  -Name ${APP_GW_FRONT_NAME} `
  -Port ${APP_GW_FRONT_PORT}

# Create App Gw Frontend Ip Config associated to Public IP
$FrontEndIpConfig = New-AzApplicationGatewayFrontendIPConfig `
  -Name ${APP_GW_FRONT_CONF_NAME} `
  -PublicIPAddress $PublicIp

# TODO uncomment it and handle update properly
# $AppGw = Get-AzApplicationGateway `
# -Name ${APP_GW_NAME} `
# -ResourceGroupName ${ARG_NAME}

# $FrontEndPort = Get-AzApplicationGatewayFrontendPort `
# -Name ${APP_GW_FRONT_NAME} `
# -ApplicationGateway $AppGw

# $FrontEndIpConfig = Get-AzApplicationGatewayFrontendIPConfig `
# -Name ${APP_GW_FRONT_CONF_NAME} `
# -ApplicationGateway $AppGw 

# ===============================================================================
# Create App Gw HttpListener for specific customer subdomain
# require: FrontEndPort, FrontEndIpConfig
# ===============================================================================

$CustomerListener = New-AzApplicationGatewayHttpListener `
  -Name ${APP_GW_HTTP_LISTE_NAME} `
  -Protocol ${APP_GW_BACK_POOL_PROTO} `
  -FrontendPort $FrontEndPort `
  -FrontendIpConfiguration $FrontEndIpConfig `
  -HostName ${APP_GW_HTTP_LISTE_HOST_NAME}

# TODO uncomment it and handle update properly
# $AppGw.HttpListeners += $CustomerListener
# $AppGw = Set-AzApplicationGateway -ApplicationGateway $AppGw

# ===============================================================================
# Create App Gw Backend
# ===============================================================================

# Create App Gw Backend Pool pointing to Customer ACG
$CustomerBackendPool = New-AzApplicationGatewayBackendAddressPool `
  -Name ${APP_GW_BACK_POOL_NAME}

# TODO uncomment it and handle update properly
#$AppGw.BackendAddressPools += $CustomerBackendPool
#$AppGw = Set-AzApplicationGateway -ApplicationGateway $AppGw

# Create App Gw Backend Http Settings
$BackendSettings = New-AzApplicationGatewayBackendHttpSettings `
  -Name ${APP_GW_BACK_HTTP_SETS_NAME} `
  -Port ${APP_GW_BACK_POOL_PORT} `
  -Protocol ${APP_GW_BACK_POOL_PROTO} `
  -CookieBasedAffinity "Disabled"

# TODO uncomment it and handle update properly
# $BackendSettings = Get-AzApplicationGatewayBackendHttpSetting `
#   -Name ${APP_GW_BACK_HTTP_SETS_NAME} `
#   -ApplicationGateway $AppGw 

# ===============================================================================
# Create App Gw Routing Rule for specific customer subdomain
# require: Listener, BackendPool, BackendSettings
# ===============================================================================

$CustomerRule = New-AzApplicationGatewayRequestRoutingRule `
  -Name ${APP_GW_ROUTING_RULE_NAME} `
  -RuleType basic `
  -BackendHttpSettings $BackendSettings `
  -HttpListener $CustomerListener `
  -BackendAddressPool $CustomerBackendPool

# TODO uncomment it and handle update properly
# $AppGw.RequestRoutingRules += $CustomerRule
# $AppGw = Set-AzApplicationGateway -ApplicationGateway $AppGw

# ===============================================================================
# Create App Gw
# require: BackendPool, BackendSettings, FrontEndIpConfig, FrontEndPort, 
#          IpConfigAppGw, Listener, Rule, Sku
# ===============================================================================

$VNet = Get-AzVirtualNetwork `
  -Name ${VNET_NAME} `
  -ResourceGroupName ${ARG_NAME}

$SubnetAppGw = Get-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_APP_GW_NAME} `
  -VirtualNetwork $VNet 

# Create App Gw IP Config
$IpConfigAppGw = New-AzApplicationGatewayIPConfiguration `
  -Name ${APP_GW_IP_CONF_NAME} `
  -Subnet $SubnetAppGw

# Create App Gw Sku
$Sku = New-AzApplicationGatewaySku -Name ${APP_GW_SKU} -Tier Standard -Capacity 2

# Create App Gw
$AppGwJob = New-AzApplicationGateway `
  -Name ${APP_GW_NAME} `
  -Location ${LOCATION} `
  -ResourceGroupName ${ARG_NAME} `
  -GatewayIpConfigurations $IpConfigAppGw `
  -FrontendIpConfigurations $FrontEndIpConfig `
  -FrontendPorts $FrontEndPort `
  -BackendHttpSettingsCollection $BackendSettings `
  -BackendAddressPools $CustomerBackendPool `
  -RequestRoutingRules $CustomerRule `
  -HttpListeners $CustomerListener `
  -Sku $Sku `
  -AsJob


#################################################################################
#### Create Key Vault for secrets
#################################################################################

New-AzKeyVault `
  -Name ${AKV_NAME} `
  -ResourceGroupName ${ARG_NAME} `
  -Location  ${LOCATION} `
  -EnabledForDeployment `
  -EnabledForDiskEncryption `
  -EnablePurgeProtection `

Get-AzKeyVault `
  -VaultName ${AKV_NAME} `
  -ResourceGroupName ${ARG_NAME} `
| Update-AzKeyVault -EnablePurgeProtection


# TODO not needed for AKV used by ACR
# $VNet = Get-AzVirtualNetwork `
#   -Name ${VNET_NAME} `
#   -ResourceGroupName ${ARG_NAME}

# $Subnet = Get-AzVirtualNetworkSubnetConfig `
# -Name ${VNET_SUB_ACI_NAME} `
# -VirtualNetwork $VNet 

# $HasEndpoints=($Subnet | Select-Object ServiceEndpoints)

# # TODO kinda redundant
# if (-not $HasEndpoints.ServiceEndpoints) {
#   $ServiceEndpoints = @{ Service = "Microsoft.KeyVault" }
# } else {
#   $Subnet.ServiceEndpoints += @{ Service = "Microsoft.KeyVault" }
#   $ServiceEndpoints = $Subnet.ServiceEndpoints.Service
# }

# Set-AzVirtualNetworkSubnetConfig `
#   -Name ${VNET_SUB_ACI_NAME} `
#   -VirtualNetwork $VNet `
#   -AddressPrefix $Subnet.AddressPrefix  `
#   -Delegation $Subnet.Delegations `
#   -NetworkSecurityGroup $Subnet.NetworkSecurityGroup `
#   -ServiceEndpoint $ServiceEndpoints `
# | Set-AzVirtualNetwork

# $RuleSet = New-AzKeyVaultNetworkRuleSetObject `
#   -DefaultAction Allow `
#   -Bypass AzureServices `
#   -IpAddressRange $Subnet.AddressPrefix `
#   -VirtualNetworkResourceId $Subnet.Id

# Add-AzKeyVaultNetworkRule `
#   -VaultName ${AKV_NAME} `
#   -IpAddressRange  `
#   -VirtualNetworkResourceId $Subnet.Id `
#   -PassThru

# NOTE
# Add-AzKeyVaultNetworkRule: Invalid value found at properties.networkAcls.ipRules[0].value: 10.0.1.0/24 belongs to forbidden range 10.0.0.0–10.255.255.255 (private IP addresses). Same for 172.16.0.0/24 and 

#################################################################################
#### Create Service Principal used by ACR for encryption and store in AKV
#################################################################################

az identity create `
  --resource-group ${ARG_NAME} `
  --name ${AMI_NAME}


$identityID=(az identity show --resource-group ${ARG_NAME}  --name ${AMI_NAME} --query 'id' --output tsv)

$identity=(az identity show --resource-group ${ARG_NAME} --name ${AMI_NAME}) | ConvertFrom-Json

$identityPrincipalID= $identity.principalId
$identitySecretUrl= $identity.clientSecretUrl

$KeyVault = Get-AzKeyVault `
-Name ${AKV_NAME} `
-ResourceGroupName ${ARG_NAME} 

# Grant full permissions to KV to current user
$UserObjectId = (az ad signed-in-user show --query 'objectId' --output tsv)

az keyvault set-policy `
  --resource-group ${ARG_NAME}  `
  --name ${AKV_NAME} `
  --object-id $UserObjectId `
  --certificate-permissions backup create delete deleteissuers get getissuers import list listissuers managecontacts manageissuers purge recover restore setissuers update `
  --key-permissions backup create decrypt delete encrypt get import list purge recover restore sign unwrapKey update verify wrapKey `
  --secret-permissions backup delete get list purge recover restore set `
  --storage-permissions backup delete deletesas get getsas list listsas purge recover regeneratekey restore set setsas update 

az keyvault set-policy `
  --resource-group ${ARG_NAME}  `
  --name ${AKV_NAME} `
  --object-id $identityPrincipalID `
  --key-permissions get unwrapKey wrapKey `
  --secret-permissions delete get list purge recover restore set

az keyvault key create `
  --name ${ACR_ENC_KEY_NAME}  `
  --vault-name ${AKV_NAME} `

$ACR_ENC_KEY_ID=(az keyvault key show `
  --name ${ACR_ENC_KEY_NAME} `
  --vault-name ${AKV_NAME} `
  --query 'key.kid' --output tsv)

$ACR_ENC_KEY_ID=(echo $ACR_ENC_KEY_ID | sed -e "s/\/[^/]*$//")

#################################################################################
#### Create Container Registry
#################################################################################

#                         BASIC	            STANDARD	        PREMIUM
# Price per day	          $0.167	          $0.667	          $1.667
# Included storage (GB)	  10	              100	              500
#                                                             * Premium offers 
#                                                             * enhanced throughput 
#                                                             * for docker pulls 
#                                                             * across multiple, 
#                                                             * concurrent nodes
# Total web hooks	        2	                10	              500
# Geo Replication	        Not Supported	    Not Supported	    Supported
#                                                             * $1.667 per 
#                                                             * replicated region

# https://azure.microsoft.com/en-us/pricing/details/container-registry/

# TODO only premium support encryption, do we need it?
# TODO --identity and --key-encryption-key must be both supplied
# TODO Premium is paid $1.677 per day. Maybe can spend few bucks?
# * FIXME we can not use AMI to cross identity ACR and ACI so use premium
# * only if other benefits usefull
az acr create `
  --resource-group ${ARG_NAME} `
  --name $ACR_NAME `
  --identity $identityID `
  --key-encryption-key $ACR_ENC_KEY_ID `
  --admin-enabled true `
  --sku Premium

  # TODO Maybe use basic, price is 
# az acr create `
#   --resource-group ${ARG_NAME} `
#   --name $ACR_NAME `
#   --sku Basic

#################################################################################
#### Create Service Principal used by ACI to pull from ACR
#### (Can not use AMI for cross identity during ACI pulling from ACR)
#################################################################################

# NOTE
# Currently, services such as Azure Web App for Containers or Azure Container Instances can't use their 
# managed identity to authenticate with Azure Container Registry when pulling a container image to deploy
# the container resource itself. The identity is only available after the container is running. To deploy 
# these resources using images from Azure Container Registry, a different authentication method such as # service principal is recommended.

# DESCRIPTION: Create AKV, RBAC Service Principal. Store RBAC creds in AKV as 
#              secrets. Then create Basic ACR and ACI with ID of RBAC secrets.
#              So that ACI can access ACR via creds that it will pull from AKV.

$AAD_ACR_PULL_PRINCIPAL_NAME="${ACR_NAME}-pull"
$AAD_ACR_PULL_CLIENT_ID_NAME="${ACR_NAME}-pull-usr"
$AAD_ACR_PULL_SECRET_NAME="${ACR_NAME}-pull-pwd"

# Create service principal, store its password in AKV (the registry *password*)
$ACR_SCOPES=(az acr show --name $ACR_NAME --query id --output tsv)
$AAD_ACR_PULL_SECRET=(az ad sp create-for-rbac `
  --name $AAD_ACR_PULL_PRINCIPAL_NAME `
  --scopes $ACR_SCOPES `
  --role acrpull `
  --query password `
  --output tsv)

az keyvault secret set `
  --vault-name $AKV_NAME `
  --name $AAD_ACR_PULL_SECRET_NAME `
  --value $AAD_ACR_PULL_SECRET

# Store service principal ID in AKV (the registry *username*)
$AAD_ACR_PULL_CLIENT_ID=(az ad sp show --id http://$AAD_ACR_PULL_PRINCIPAL_NAME --query appId --output tsv)

az keyvault secret set `
    --vault-name $AKV_NAME `
    --name $AAD_ACR_PULL_CLIENT_ID_NAME `
    --value $AAD_ACR_PULL_CLIENT_ID


#################################################################################
#### Create MySQL Server within VNet Subnet
#################################################################################

# ===============================================================================
# Create MySQL Server
# ===============================================================================

$MyModule = "Az.MySql"
if(-not (Get-Module -ListAvailable -Name $MyModule)) {
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    Install-Module -Name $MyModule -Confirm:$False
    Import-Module -name $MyModule
}

# Install `mysql` cli on Azure Powershell
$MyModule = "SimplySql"
if(-not (Get-Module -ListAvailable -Name $MyModule)) {
  Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
  Install-Module -Name $MyModule -Confirm:$False
  Import-Module -name $MyModule
}


$MySqlAdminLoginPassword = ${MYSQL_ROOT_PASSWORD} | ConvertTo-SecureString -AsPlainText -Force

# FIXME: preview kinda broken
# New-AzMySqlFlexibleServer `
#   -Name  ${MY_SQL_SRV_FLEX_NAME} `
#   -ResourceGroupName  ${ARG_NAME}` 
#   -AdministratorLoginPassword  $AdminLoginPassword `
#   -AdministratorUserName  ${MYSQL_ROOT_USERNAME} `
#   -BackupRetentionDay  7 `
#   -HighAvailability Disabled `
#   -Location  ${LOCATION} `
#   -Sku Standard_B1s_v1 `
#   -SkuTier  Burstable `
#   -StorageInMb 5120 `
#   -Subnet  ${VNET_SUB_MYSQL_SRV} `
#   -Vnet ${VNET_NAME} `
#   -Version  8.0.21 `
#   -Zone 1 # `-AsJob

# FIXME: $MinTLS and $v8_0 will not work without calling some method first
#        Maybe with that it will work
Get-AzMySqlServer  -ResourceGroupName ${ARG_NAME}

# MinimalTlsVersionEnum
#  Tls10 = @"TLS1_0";
#  Tls11 = @"TLS1_1";
#  Tls12 = @"TLS1_2";
#  TlsEnforcementDisabled = @"TLSEnforcementDisabled";
$MinTLS = [Microsoft.Azure.PowerShell.Cmdlets.MySql.Support.MinimalTlsVersionEnum]::TlsEnforcementDisabled

# ServerVersion
#  Eight0 = @"8.0";
#  Five6 = @"5.6";
#  Five7 = @"5.7";
$v8_0 = [Microsoft.Azure.PowerShell.Cmdlets.MySql.Support.ServerVersion]::Eight0

# The Sku parameter value follows the convention 
# pricing-tier_compute-generation_vCores 
# as shown in the following examples:
#   -Sku B_Gen5_1 maps to Basic, Gen 5, and 1 vCore. This option is the smallest SKU available.
#   -Sku GP_Gen5_32 maps to General Purpose, Gen 5, and 32 vCores.
#   -Sku MO_Gen5_2 maps to Memory Optimized, Gen 5, and 2 vCores.

# IMPORTANT 
# New-AzMySqlVirtualNetworkRule_CreateExpanded: This feature is not available 
# for the selected edition 'Basic', has to use SKU: General Purpose!


$MySqLSrvJob = New-AzMySqlServer `
  -Name ${MY_SQL_SRV_NAME} `
  -Location ${LOCATION} `
  -ResourceGroupName ${ARG_NAME} `
  -AdministratorLoginPassword $MySqlAdminLoginPassword `
  -AdministratorUsername ${MYSQL_ROOT_LOGIN} `
  -Sku GP_Gen5_2 `
  -Version $v8_0 `
  -StorageInMb (5 * 1024) `
  -MinimalTlsVersion $MinTLS  `
  -SslEnforcement Disabled `
  -StorageAutogrow Enabled `
  -AsJob 


#################################################################################
#### Create Container Group for Customer
#################################################################################

# No support for VNET in PS1: New-AzContainerGroup
# https://github.com/Azure/azure-powershell/issues/12218

# Create Container Group with one container
$title = "${ARG_NAME}_${ACI_NAME}_${VNET_NAME}_${VNET_SUB_ACI_NAME}"

# from public registry
# az container create `
#   --name ${ACI_NAME} `
#   --resource-group ${ARG_NAME} `
#   --image ${ACI_IMAGE} `
#   --vnet ${VNET_NAME} `
#   --subnet ${VNET_SUB_ACI_NAME} `
#   --environment-variables "TITLE=$title"

# from private registry: require  registry-login-server...
# NOTE: pulling via assigned AMI is not supported in ACI

az container create `
  --name ${ACI_NAME} `
  --location $LOCATION `
  --resource-group ${ARG_NAME} `
  --image ${ACI_IMAGE} `
  --assign-identity $identityID `
  --registry-login-server "${ACR_NAME}.azurecr.io" `
  --registry-username ${AAD_ACR_PULL_CLIENT_ID} `
  --registry-password ${AAD_ACR_PULL_SECRET} `
  --environment-variables `
    "TITLE=$title" `
    "MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}" `
    "MYSQL_DATABASE_PASSWORD=${MYSQL_ROOT_PASSWORD}" `
    "MYSQL_DATABASE_USER=${MYSQL_ROOT_USERNAME}" `
    "MYSQL_DATABASE_HOST=${MYSQL_DATABASE_HOST}" `
    "MYSQL_DATABASE_PORT=${MYSQL_DATABASE_PORT}" `
    "MYSQL_DATABASE_DB=${MYSQL_DATABASE_DB}"
    

# ===============================================================================
# In Aci Subnet at VNet add Service Endpoint for MySQL Server
# ===============================================================================



$VNet = Get-AzVirtualNetwork `
  -Name ${VNET_NAME} `
  -ResourceGroupName ${ARG_NAME}

$Subnet = Get-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_ACI_NAME} `
  -VirtualNetwork $VNet `
  -ErrorVariable notPresent -ErrorAction SilentlyContinue


if ($notPresent -or -not $Subnet) {

}

Set-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_ACI_NAME} `
  -VirtualNetwork $VNet `
  -AddressPrefix $Subnet.AddressPrefix `
  -Delegation $Subnet.Delegations `
  -NetworkSecurityGroup $Subnet.NetworkSecurityGroup `
  -ServiceEndpoint Microsoft.Sql `
| Set-AzVirtualNetwork

$VNet = Get-AzVirtualNetwork `
  -Name ${VNET_NAME} `
  -ResourceGroupName ${ARG_NAME}

$Subnet = Get-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_ACI_NAME} `
  -VirtualNetwork $VNet 

do {
  echo "Waiting for MySqLSrvJob  to finish, state: ", $MySqLSrvJob.State
  Start-Sleep -Seconds 10
} while ($MySqLSrvJob.State -Match 'Running')

$MySqlSrv = (Get-AzMySqlServer -Name ${MY_SQL_SRV_NAME} -ResourceGroupName ${ARG_NAME})
$ServiceName = $MySqlSrv.Type


mysql -h $MYSQL_DATABASE_HOST -u ${MYSQL_ROOT_USERNAME} -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW VARIABLES LIKE '%version%';"

az mysql db create --resource-group ${ARG_NAME} --server-name ${MY_SQL_SRV_NAME} --name ${MYSQL_DATABASE_DB} 


$MySqlVnetRuleJob = New-AzMySqlVirtualNetworkRule `
  -Name ${MY_SQL_SRV_VNET_RULE_NAME} `
  -ServerName ${MY_SQL_SRV_NAME} `
  -ResourceGroupName ${ARG_NAME} `
  -SubnetId $Subnet.Id `
  -AsJob

do {
    echo "Waiting for MySqlVnetRuleJob to finish, state: ", $MySqlVnetRuleJob.State
    Start-Sleep -Seconds 10
} while ($MySqlVnetRuleJob.State -Match 'Running')

# ===============================================================================
# Get Container Group Ip
# ===============================================================================

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

# ===============================================================================
# Create Network Security Group with Rules and Associate to ACI Subnet
# Rules: Rule100_Outbound_Allow_FromVnet_ToMySql, 
#        Rule110_Outbound_Deny_FromVnet_ToInternet
# ===============================================================================

$Rule100 = New-AzNetworkSecurityRuleConfig `
-Name Rule100_Outbound_Allow_FromVnet_ToMySql `
-Description "Allow outbound access to MySQL on port 3306" `
-Priority 100 `
-Access Allow `
-Protocol TCP `
-Direction Outbound `
-SourceAddressPrefix VirtualNetwork `
-SourcePortRange '*' `
-DestinationAddressPrefix Sql `
-DestinationPortRange 3306

$Rule110 = New-AzNetworkSecurityRuleConfig `
-Name Rule110_Outbound_Deny_FromVnet_ToInternet `
-Description "Block outbound access to Internet" `
-Priority 110 `
-Access Deny `
-Protocol '*' `
-Direction Outbound `
-SourceAddressPrefix VirtualNetwork `
-SourcePortRange '*' `
-DestinationAddressPrefix Internet `
-DestinationPortRange '*'

$AciNSG = New-AzNetworkSecurityGroup `
-ResourceGroupName ${ARG_NAME} `
-Location ${LOCATION} `
-Name ${ACI_NET_SEC_GR_NAME} `
-SecurityRules $Rule100,$Rule110

$VNet = Get-AzVirtualNetwork `
  -Name ${VNET_NAME} `
  -ResourceGroupName ${ARG_NAME}

$Subnet = Get-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_ACI_NAME} `
  -VirtualNetwork $VNet 

Set-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_ACI_NAME} `
  -VirtualNetwork $VNet `
  -AddressPrefix $Subnet.AddressPrefix `
  -Delegation $Subnet.Delegations `
  -NetworkSecurityGroup $AciNSG `
  -ServiceEndpoint Microsoft.Sql `
| Set-AzVirtualNetwork



# ===============================================================================
# Create Network Security Group with Rules and Associate to AppGw Subnet
# Rules: Rule100_Outbound_Allow_FromVnet_ToMySql, 
#        Rule110_Outbound_Deny_FromVnet_ToInternet
# ===============================================================================


$Rule100 = New-AzNetworkSecurityRuleConfig `
-Name Rule100_Allow_TCP_FromInternet_ToVirtualNetwork `
-Description "Allow inbound from Internet to VirtualNetwork" `
-Priority 100 `
-Access Allow `
-Protocol TCP `
-Direction Inbound `
-SourceAddressPrefix Internet `
-SourcePortRange '*' `
-DestinationAddressPrefix VirtualNetwork `
-DestinationPortRange 80

$Rule1000 = New-AzNetworkSecurityRuleConfig `
-Name Rule1000_Allow_TCP_FromGatewayManager_ToAny `
-Description "Allow inbound access to GatewayManager" `
-Priority 1000 `
-Access Allow `
-Protocol TCP `
-Direction Inbound `
-SourceAddressPrefix GatewayManager `
-SourcePortRange '*' `
-DestinationAddressPrefix '*' `
-DestinationPortRange '65200-65535'

$Rule1010 = New-AzNetworkSecurityRuleConfig `
-Name Rule1010_Allow_AnyProto_FromAzureLoadBalancer_ToAny `
-Description "Allow inbound access to AzureLoadBalancer" `
-Priority 1010 `
-Access Allow `
-Protocol TCP `
-Direction Inbound `
-SourceAddressPrefix AzureLoadBalancer `
-SourcePortRange '*' `
-DestinationAddressPrefix '*' `
-DestinationPortRange '*'

$Rule1020 = New-AzNetworkSecurityRuleConfig `
-Name Rule1020_Allow_AnyProto_FromVirtualNetwork_ToAny `
-Description "Allow inbound access to VirtualNetwork" `
-Priority 1020 `
-Access Allow `
-Protocol '*' `
-Direction Inbound `
-SourceAddressPrefix VirtualNetwork `
-SourcePortRange '*' `
-DestinationAddressPrefix '*' `
-DestinationPortRange '*'

$NSG = New-AzNetworkSecurityGroup `
-ResourceGroupName ${ARG_NAME} `
-Location ${LOCATION} `
-Name ${APP_GW_NET_SEC_GR_NAME} `
-SecurityRules $Rule100,$Rule1000,$Rule1010,$Rule1020

$VNet = Get-AzVirtualNetwork `
  -Name ${VNET_NAME} `
  -ResourceGroupName ${ARG_NAME}

$Subnet = Get-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_APP_GW_NAME} `
  -VirtualNetwork $VNet 

Set-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_APP_GW_NAME} `
  -VirtualNetwork $VNet `
  -AddressPrefix $Subnet.AddressPrefix `
  -Delegation $Subnet.Delegations `
  -NetworkSecurityGroup $NSG `
| Set-AzVirtualNetwork


# ===============================================================================
# Get App Gw Backend Pool Server Addresses and append private IP of ACI
# ===============================================================================

do {
  echo "Waiting for AppGwJob to finish: "
  $AppGwJob
  Start-Sleep -Seconds 10
} while ($AppGwJob.State -Match 'Running')

$AppGw = Get-AzApplicationGateway -Name ${APP_GW_NAME}  -ResourceGroupName ${ARG_NAME}

$BackendPool = Get-AzApplicationGatewayBackendAddressPool -Name ${APP_GW_BACK_POOL_NAME} -ApplicationGateway $AppGw

$BackendPool.BackendAddresses += @{ IpAddress = $ACG.IpAddress }

# Create Backend Pool in APP GW that will route to private IP of Container Group  
$AppGw = Set-AzApplicationGatewayBackendAddressPool -Name ${APP_GW_BACK_POOL_NAME} -ApplicationGateway $AppGw -BackendIPAddresses $BackendPool.BackendAddresses.IpAddress

# Update App Gw
$AppGw = Set-AzApplicationGateway -ApplicationGateway $AppGw


#################################################################################
#### Test App Gw public Ip pointing to customer Container Group
#################################################################################


# Get public IP of APP GW 
$PUB_IP=$(az network public-ip show `
--resource-group ${ARG_NAME} `
--name ${PUB_IP_NAME} `
--query [ipAddress] `
--output tsv)

curl $PUB_IP

echo $PUB_IP

echo "Go to azure portal and tweak accordingly the resources. Then download deployment of whole resource group, clean up, and ship it."
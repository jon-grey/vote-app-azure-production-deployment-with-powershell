

Set-StrictMode -Version Latest

. .env.ps1

echo '
# ===============================================================================
# Create Network Security Group with Rules and Associate to ACI Subnet
# Rules: Rule100_Outbound_Allow_FromVnet_ToMySql, 
#        Rule110_Outbound_Deny_FromVnet_ToInternet
# ==============================================================================='

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

$HasEndpoints=($Subnet | Select-Object ServiceEndpoints)

# TODO kinda redundant
if (-not $HasEndpoints.ServiceEndpoints) {
  $ServiceEndpoints = $null
} else {
  $ServiceEndpoints = $Subnet.ServiceEndpoints
}


Set-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_ACI_NAME} `
  -VirtualNetwork $VNet `
  -AddressPrefix $Subnet.AddressPrefix `
  -Delegation $Subnet.Delegations `
  -NetworkSecurityGroup $AciNSG `
  -ServiceEndpoint $ServiceEndpoints `
| Set-AzVirtualNetwork

echo '
# ===============================================================================
# Create Network Security Group with Rules and Associate to AppGw Subnet
# Rules: Rule100_Outbound_Allow_FromVnet_ToMySql, 
#        Rule110_Outbound_Deny_FromVnet_ToInternet
# ==============================================================================='


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
-DestinationPortRange ${ACI_PORT}

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


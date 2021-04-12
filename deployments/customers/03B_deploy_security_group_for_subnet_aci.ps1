

Set-StrictMode -Version Latest

. .env.ps1

do {
  $AppGw = Get-AzApplicationGateway -Name ${APP_GW_NAME}  -ResourceGroupName ${ARG_NAME} -ErrorVariable notPresent -ErrorAction SilentlyContinue
  if ($notPresent -or -not $AppGw){
    Start-Sleep -Seconds 10
  } else {
    break
  }
} while ($true)


do {
  $AppGw = Get-AzApplicationGateway -Name ${APP_GW_NAME}  -ResourceGroupName ${ARG_NAME}
  if ($AppGw.ProvisioningState -notmatch "Succeeded" -or  $AppGw.OperationalState -notmatch "Running"){
    echo "[$(date)] Waiting for AppGw to have ProvisioningState $($AppGw.ProvisioningState)/Succeeded, OperationalState $($AppGw.OperationalState)/Running..."
    Start-Sleep -Seconds 10
  } else {
    break
}} while ($true)


echo '
# ===============================================================================
# Create Network Security Group with Rules and Associate to ACI Subnet
# Rules: Rule100_Outbound_Allow_FromVnet_ToMySql, 
#        Rule110_Outbound_Deny_FromVnet_ToInternet
# TODO: check if SecGroups should be separate for each ACI where Allowed 
# TODO: Inbound rules should be from Subnet assigned to customer not from VNET
==============================================================================='

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

$VNet = Get-AzVirtualNetwork `
  -Name ${VNET_NAME} `
  -ResourceGroupName ${ARG_NAME}

$AciNSG = New-AzNetworkSecurityGroup `
  -ResourceGroupName ${ARG_NAME} `
  -Location ${LOCATION} `
  -Name ${ACI_NET_SEC_GR_NAME} `
  -SecurityRules $Rule100,$Rule110

$CUSTOMERS_IDX.forEach({
    $CustomerId = $_
    $Customer = $CUSTOMERS_MAP[$CustomerId]
  
    echo "===== Set SecGroup $ACI_NET_SEC_GR_NAME for Subnet $(${Customer}.VNET_SUB_ACI_NAME) for CustomerId: $CustomerId"

    $Subnet = Get-AzVirtualNetworkSubnetConfig `
      -Name ${Customer}.VNET_SUB_ACI_NAME `
      -VirtualNetwork $VNet 

    $HasEndpoints=($Subnet | Select-Object ServiceEndpoints)
    if (-not $HasEndpoints.ServiceEndpoints) {
      $ServiceEndpoints = $null
    } else {
      $ServiceEndpoints = $Subnet.ServiceEndpoints.Service
    }

    $VNet = Set-AzVirtualNetworkSubnetConfig `
      -Name ${Customer}.VNET_SUB_ACI_NAME`
      -VirtualNetwork $VNet `
      -AddressPrefix $Subnet.AddressPrefix `
      -Delegation $Subnet.Delegations `
      -ServiceEndpoint $ServiceEndpoints `
      -NetworkSecurityGroup $AciNSG
})
  
$VNet | Set-AzVirtualNetwork 


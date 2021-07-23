Set-StrictMode -Version Latest

. .env.ps1


echo '
# ===============================================================================
# Add new Subnets for Customer ACI to VNet with Microsoft.Sql in ServiceEndpoints 
# ==============================================================================='

[System.Int32] $Counter = 0

$VNet = Get-AzVirtualNetwork `
  -Name ${VNET_NAME} `
  -ResourceGroupName ${ARG_NAME}
# Create subnet config for customer ACG

$IpAddress = Set-IpSubnetOctet 10.0.0.0/24 (++$Counter) 2

Add-AzVirtualNetworkSubnetConfig `
    -Name $VNET_SUB_ACI_DUMMY_NAME `
    -VirtualNetwork $VNet `
    -AddressPrefix $IpAddress

$CUSTOMERS_IDX.forEach({
  $CustomerId = $_
  $C = $CUSTOMERS_MAP[$CustomerId]
  $IpAddress = Set-IpSubnetOctet 10.0.0.0/24 (++$Counter) 2

  echo "===== Add new Subnet with IP $IpAddress for CustomerId: $CustomerId"
  
  $VNet = Add-AzVirtualNetworkSubnetConfig `
      -Name ${C}.VNET_SUB_ACI_NAME `
      -VirtualNetwork $VNet `
      -AddressPrefix $IpAddress `
      -ServiceEndpoint Microsoft.Sql
})

$VNet | Set-AzVirtualNetwork 
# Subnets per virtual network	limit: 3,000
  
  







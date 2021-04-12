Set-StrictMode -Version Latest

. .env.ps1

echo '
# ===============================================================================
# Add new Subnet for AAG to VNET
# ==============================================================================='


$VNet = Get-AzVirtualNetwork `
  -Name ${VNET_NAME} `
  -ResourceGroupName ${ARG_NAME}

# Create subnet config for App GW
Add-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_APP_GW_NAME} `
  -VirtualNetwork $VNet `
  -AddressPrefix 10.0.0.0/24 | Set-AzVirtualNetwork


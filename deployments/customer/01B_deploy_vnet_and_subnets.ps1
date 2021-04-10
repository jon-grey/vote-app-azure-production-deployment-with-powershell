Set-StrictMode -Version Latest

. .env.ps1

echo '
#################################################################################
#### Create VNET
#################################################################################'

$VNet = New-AzVirtualNetwork `
  -Name ${VNET_NAME} `
  -ResourceGroupName ${ARG_NAME} `
  -Location ${LOCATION} `
  -AddressPrefix 10.0.0.0/16 

echo '
# ===============================================================================
# Add new Subnet for ACI to VNet
# ==============================================================================='
$ErrorActionPreferencePrev = $ErrorActionPreference 
$ErrorActionPreference = "Continue"

$VNet = Get-AzVirtualNetwork `
  -Name ${VNET_NAME} `
  -ResourceGroupName ${ARG_NAME}


# Create subnet config for App GW
Add-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_APP_GW_NAME} `
  -VirtualNetwork $VNet `
  -AddressPrefix 10.0.0.0/24 | Set-AzVirtualNetwork

echo '
# ===============================================================================
# Add new Subnet for ACI to VNet
# ==============================================================================='

$VNet = Get-AzVirtualNetwork `
  -Name ${VNET_NAME} `
  -ResourceGroupName ${ARG_NAME}
# Create subnet config for customer ACG

Add-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_ACI_NAME} `
  -VirtualNetwork $VNet `
  -AddressPrefix 10.0.1.0/24 `
| Set-AzVirtualNetwork

$ErrorActionPreference = $ErrorActionPreferencePrev

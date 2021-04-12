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


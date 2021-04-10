Set-StrictMode -Version Latest

. .env.ps1

echo '
#################################################################################
#### Create Public Ip
#################################################################################

# TODO handle cases of Public IP and AppGW
# * 1. Public IP Basic Tier with Dynamic IP + App GW Standard (Small)
# * 2. Public IP Standard Tier with Static IP + App Gw Standard_v2 (Small)
'

if ($APP_GW_SKU_TIER.ToLower() -notmatch "Standard_v2".ToLower()) { # case 1
  $PUB_IP_ALLOCATION_METHOD="Static"
  $PUB_IP_SKU="Basic"
} elseif ($APP_GW_SKU_TIER.ToLower() -match "Standard_v2".ToLower()) { # case 2
  $PUB_IP_ALLOCATION_METHOD="Static"
  $PUB_IP_SKU="Standard"
} else {
  throw "Bad thing happened. Case with APP_GW_SKU_TIER=$APP_GW_SKU_TIER not supported."
}

# Create Public IP
$PublicIp = New-AzPublicIpAddress `
  -ResourceGroupName ${ARG_NAME} `
  -Name ${PUB_IP_NAME} `
  -Location ${LOCATION} `
  -AllocationMethod ${PUB_IP_ALLOCATION_METHOD} `
  -Sku $PUB_IP_SKU `
  -Tier ${PUB_IP_TIER} `
  -DomainNameLabel ${DNS_ZONE_NAME}.Split('.')[0]

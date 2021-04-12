Set-StrictMode -Version Latest

. ./.env.ps1

echo '
#################################################################################
#### Create Key Vault for secrets
#################################################################################'
# $ErrorActionPreferencePrev = $ErrorActionPreference 
# $ErrorActionPreference = "Continue"
# $ErrorActionPreference = $ErrorActionPreferencePrev


echo '
# ===============================================================================
# Try to create AKV
# ==============================================================================='

$KevVault = New-AzKeyVault `
  -Name ${AKV_NAME} `
  -ResourceGroupName ${ARG_NAME} `
  -Location  ${LOCATION} `
  -EnabledForDeployment `
  -EnabledForDiskEncryption `
  -EnablePurgeProtection `
  -ErrorVariable notPresent `
  -ErrorAction SilentlyContinue

if ($notPresent -or -not $KevVault) {
  echo '
  # ===============================================================================
  # Could not create AKV. Try to undo removal.
  # ==============================================================================='
  $KevVault = Undo-AzKeyVaultRemoval `
  -VaultName ${AKV_NAME} `
  -ResourceGroupName ${ARG_NAME} `
  -Location ${LOCATION} `
  -ErrorVariable notPresent `
  -ErrorAction SilentlyContinue
}

echo '
# ===============================================================================
# Get AKV
# ==============================================================================='
$KevVault = Get-AzKeyVault `
  -VaultName ${AKV_NAME} `
  -ResourceGroupName ${ARG_NAME} `
  -ErrorVariable notPresent `
  -ErrorAction SilentlyContinue

if ($notPresent -or -not $KevVault) {
  Write-Error "Could not get AKV. Abort."
}

if (!KeyVault.)

$KevVault | Update-AzKeyVault -EnablePurgeProtection

$KeyVault = Get-AzKeyVault `
  -VaultName ${AKV_NAME} `
  -ResourceGroupName ${ARG_NAME}

$KeyVault

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


# echo '
# # ===============================================================================
# # Grant full permissions to KV to current user
# # ==============================================================================='

# $MyModule = "Az.Resources"
# if(-not (Get-Module -ListAvailable -Name $MyModule)) {
#   Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
#   Install-Module -Name $MyModule -Confirm:$False
#   Import-Module -name $MyModule
# }

# $User = Get-AzADUser

# az keyvault set-policy `
#   --resource-group ${ARG_NAME}  `
#   --name ${AKV_NAME} `
#   --object-id $User.Id `
#   --certificate-permissions backup create delete deleteissuers get getissuers import list listissuers managecontacts manageissuers purge recover restore setissuers update `
#   --key-permissions backup create decrypt delete encrypt get import list purge recover restore sign unwrapKey update verify wrapKey `
#   --secret-permissions backup delete get list purge recover restore set `
#   --storage-permissions backup delete deletesas get getsas list listsas purge recover regeneratekey restore set setsas update 
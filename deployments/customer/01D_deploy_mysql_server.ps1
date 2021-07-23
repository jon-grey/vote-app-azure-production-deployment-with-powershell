Set-StrictMode -Version Latest

. .env.ps1

echo '
#################################################################################
#### Create MySQL Server within VNet Subnet
#################################################################################'


echo '
# ===============================================================================
# Create MySQL Server
# ==============================================================================='

Setup-Module "Az.MySql"
Setup-Module "SimplySql"


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

echo '
# The Sku parameter value follows the convention 
# pricing-tier_compute-generation_vCores 
# as shown in the following examples:
#   -Sku B_Gen5_1 maps to Basic, Gen 5, and 1 vCore. This option is the smallest SKU available.
#   -GP_Gen5_2 smallest GP
#   -Sku GP_Gen5_32 maps to General Purpose, Gen 5, and 32 vCores.
#   -Sku MO_Gen5_2 maps to Memory Optimized, Gen 5, and 2 vCores.

# IMPORTANT To create Service Enpoint  
# New-AzMySqlVirtualNetworkRule_CreateExpanded: This feature is not available 
# for the selected edition Basic, has to use SKU: General Purpose!
'

$MySqlAdminLoginPassword = $CUSTOMER.MYSQL_ROOT_PASSWORD | ConvertTo-SecureString -AsPlainText -Force

$MySqLSrvJob = New-AzMySqlServer `
  -Name $CUSTOMER.MY_SQL_SRV_NAME `
  -Location ${LOCATION} `
  -ResourceGroupName ${ARG_NAME} `
  -AdministratorLoginPassword $MySqlAdminLoginPassword `
  -AdministratorUsername $CUSTOMER.MYSQL_ROOT_LOGIN `
  -Sku GP_Gen5_2 `
  -Version $v8_0 `
  -StorageInMb (5 * 1024) `
  -MinimalTlsVersion $MinTLS  `
  -SslEnforcement Disabled `
  -StorageAutogrow Enabled `
  -AsJob 

Start-Sleep -Seconds 10

if ($MySqLSrvJob.State -Match "Failed") {
  Write-Error "[ERROR] MySqLSrvJob failed. $MySqLSrvJob"
}

echo $MySqLSrvJob
Set-StrictMode -Version Latest

. .env.ps1

echo '
# ===============================================================================
# In MySQL Server add VNET Rule of Service Endpoint for ACI Subnet
# ==============================================================================='

do {
  $MySqlSrv = Get-AzMySqlServer `
  -Name $CUSTOMER.MY_SQL_SRV_NAME `
  -ResourceGroupName ${ARG_NAME} `
  -ErrorVariable notPresent `
  -ErrorAction SilentlyContinue

  if ($notPresent -or -not $MySqlSrv) {
    echo "[$(date)] Waiting for MySqlSrv to be present..."
    Start-Sleep -Seconds 10
  } else {
    break
  }
} while ($true)

# For testing. 
# NOTE it will fail without enabling connection in MySQL firewall. 
# NOTE we dont want to use firewall beside this test.
# mysql -h $MYSQL_DATABASE_HOST -u ${MYSQL_ROOT_USERNAME} -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW VARIABLES LIKE '%version%';"

az mysql db create --resource-group ${ARG_NAME} --server-name $CUSTOMER.MY_SQL_SRV_NAME --name $CUSTOMER.MYSQL_DATABASE_DB


$VNet = Get-AzVirtualNetwork `
  -Name ${VNET_NAME} `
  -ResourceGroupName ${ARG_NAME}

$Subnet = Get-AzVirtualNetworkSubnetConfig `
  -Name $CUSTOMER.VNET_SUB_ACI_NAME `
  -VirtualNetwork $VNet 

$MySqlVnetRuleJob = New-AzMySqlVirtualNetworkRule `
  -Name $MY_SQL_SRV_VNET_RULE_NAME `
  -ServerName $CUSTOMER.MY_SQL_SRV_NAME `
  -ResourceGroupName ${ARG_NAME} `
  -SubnetId $Subnet.Id `
  -AsJob

do {
    echo "Waiting for MySqlVnetRuleJob to finish, state: $($MySqlVnetRuleJob.State)"
    Start-Sleep -Seconds 10
} while ($MySqlVnetRuleJob.State -Match 'Running')

if ($MySqlVnetRuleJob.State -Match "Failed") {
    Write-Error "[ERROR] MySqlVnetRuleJob failed. $MySqlVnetRuleJob"
}


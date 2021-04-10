Set-StrictMode -Version Latest

. .env.ps1

echo '
# ===============================================================================
# In Aci Subnet at VNet add Service Endpoint for MySQL Server
# ==============================================================================='

do {
    echo "Waiting for MySqLSrvJob  to finish, state: ", $MySqLSrvJob.State
    Start-Sleep -Seconds 10
  } while ($MySqLSrvJob.State -Match 'Running')
  
  $MySqlSrv = (Get-AzMySqlServer -Name ${MY_SQL_SRV_NAME} -ResourceGroupName ${ARG_NAME})
  $ServiceName = $MySqlSrv.Type
  
  
  # For testing. NOTE it will fail without enabling connection in MySQL firewall. 
  # NOTE we dont want to use firewall beside this test.
  # mysql -h $MYSQL_DATABASE_HOST -u ${MYSQL_ROOT_USERNAME} -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW VARIABLES LIKE '%version%';"
  
  az mysql db create --resource-group ${ARG_NAME} --server-name ${MY_SQL_SRV_NAME} --name ${MYSQL_DATABASE_DB} 
  
  
  $VNet = Get-AzVirtualNetwork `
    -Name ${VNET_NAME} `
    -ResourceGroupName ${ARG_NAME}
  
  $Subnet = Get-AzVirtualNetworkSubnetConfig `
    -Name ${VNET_SUB_ACI_NAME} `
    -VirtualNetwork $VNet 
  
  $MySqlVnetRuleJob = New-AzMySqlVirtualNetworkRule `
    -Name ${MY_SQL_SRV_VNET_RULE_NAME} `
    -ServerName ${MY_SQL_SRV_NAME} `
    -ResourceGroupName ${ARG_NAME} `
    -SubnetId $Subnet.Id `
    -AsJob
  
  do {
      echo "Waiting for MySqlVnetRuleJob to finish, state: $($MySqlVnetRuleJob.State)"
      Start-Sleep -Seconds 10
  } while ($MySqlVnetRuleJob.State -Match 'Running')
  


echo '
# ===============================================================================
# In Aci Subnet add Service Endpoint type
# ==============================================================================='

$VNet = Get-AzVirtualNetwork `
  -Name ${VNET_NAME} `
  -ResourceGroupName ${ARG_NAME}

$Subnet = Get-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_ACI_NAME} `
  -VirtualNetwork $VNet 

Set-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_ACI_NAME} `
  -VirtualNetwork $VNet `
  -AddressPrefix $Subnet.AddressPrefix `
  -Delegation $Subnet.Delegations `
  -NetworkSecurityGroup $Subnet.NetworkSecurityGroup `
  -ServiceEndpoint Microsoft.Sql `
| Set-AzVirtualNetwork
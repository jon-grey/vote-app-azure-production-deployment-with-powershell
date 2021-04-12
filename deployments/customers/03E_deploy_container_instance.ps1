Set-StrictMode -Version Latest

. .env.ps1

do {
  $AppGw = Get-AzApplicationGateway -Name ${APP_GW_NAME}  -ResourceGroupName ${ARG_NAME} -ErrorVariable notPresent -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 10
} while ($notPresent -or -not $AppGw)


do {
  $AppGw = Get-AzApplicationGateway -Name ${APP_GW_NAME}  -ResourceGroupName ${ARG_NAME}
  Start-Sleep -Seconds 10
  echo "[$(date)] Waiting for AppGw to have ProvisioningState $($AppGw.ProvisioningState)/Succeeded, OperationalState $($AppGw.OperationalState)/Running..."
} while ($AppGw.ProvisioningState -notmatch "Succeeded" -or  $AppGw.OperationalState -notmatch "Running")


echo '
#################################################################################
#### Create Container Group for Customer
#################################################################################

# No support for VNET in PS1: New-AzContainerGroup
# https://github.com/Azure/azure-powershell/issues/12218

# Create Container Group with one container

# from public registry

# from private registry: require  registry-login-server...
# NOTE: pulling via assigned AMI is not supported in ACI
'

echo '
#################################################################################
##### Create 2 x dummy ACI.
##### * 1) To fix <Network Profile> issue (first ACI deployment always fail)
##### * 2) To have some 2 x dummy ACI for testing.
#################################################################################'

echo "
# ===============================================================================
# Create ACI containerinstance-dummy-000 from public repo 
# ==============================================================================="

$Output = $null
$counter = 0
do {
  echo "
  # ==================== Repeat number $counter ===================="
  $counter += 1

  Start-Sleep -Seconds 5
  
  $Output = ( `
  az container create `
    --name "containerinstance-dummy-000" `
    --resource-group ${ARG_NAME} `
    --image ${ACI_DUMMY_IMAGE} `
    --vnet ${VNET_NAME} `
    --subnet ${VNET_SUB_ACI_DUMMY_NAME} `
    --environment-variables "TITLE='dummy-000'" `
    | ConvertFrom-Json) 
} while (!$Output)

echo "
# ===============================================================================
# Create ACI containerinstance-dummy-001 from public repo 
# ==============================================================================="

az container create `
  --name "containerinstance-dummy-001" `
  --resource-group ${ARG_NAME} `
  --image ${ACI_DUMMY_IMAGE} `
  --vnet ${VNET_NAME} `
  --subnet ${VNET_SUB_ACI_DUMMY_NAME} `
  --environment-variables "TITLE='dummy-001'" `


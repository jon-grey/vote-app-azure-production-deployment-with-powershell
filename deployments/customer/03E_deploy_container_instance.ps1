Set-StrictMode -Version Latest

. .env.ps1


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

echo "
# ===============================================================================
# Get SP for to build with image from ACR
# ==============================================================================="

# * ERROR when using powershell emulator on linux
# * https://docs.microsoft.com/en-us/answers/questions/101920/creation-of-service-principal-failing-with-error-r.html

# $AAD_ACR_PULL = New-AzADServicePrincipal `
#   -Role acrpull `
#   -Scope $ACR_SCOPES  `
#   -DisplayName $AAD_ACR_PULL_PRINCIPAL_NAME 

  
# Write-Host $AAD_ACR_PULL
  
$AAD_ACR_PULL = Get-Content ../../.files/AAD_ACR_PULL.json  | ConvertFrom-Json
echo $AAD_ACR_PULL
  

echo "
# ===============================================================================
# Create ACI ${ACI_NAME} 
# via ACR image ${ACI_IMAGE} 
# ===============================================================================

# TODO fist go to vote-app-docker-compose-build-push-to-azure-container-registry
# TODO and do `bash push-images-to-azure-container-registry.sh`
# TODO has to wait for image in registry, maybe FIXME and find some smart way of waiting here
"

# Pause "Before continuing build and push docker image to registry..."

Function az_container_create_for_customer() {
  az container create `
    --name $CUSTOMER.ACI_NAME `
    --location $LOCATION `
    --resource-group ${ARG_NAME} `
    --image ${ACI_IMAGE} `
    --vnet ${VNET_NAME} `
    --subnet $CUSTOMER.VNET_SUB_ACI_NAME `
    --registry-login-server "${ACR_NAME_LOW}.azurecr.io" `
    --registry-username $AAD_ACR_PULL.appId `
    --registry-password $AAD_ACR_PULL.password `
    --environment-variables `
      "TITLE=$($CUSTOMER.ACI_TITLE)" `
      "MYSQL_ROOT_PASSWORD=$($CUSTOMER.MYSQL_ROOT_PASSWORD)" `
      "MYSQL_DATABASE_PASSWORD=$($CUSTOMER.MYSQL_ROOT_PASSWORD)" `
      "MYSQL_DATABASE_USER=$($CUSTOMER.MYSQL_ROOT_USERNAME)" `
      "MYSQL_DATABASE_HOST=$($CUSTOMER.MYSQL_DATABASE_HOST)" `
      "MYSQL_DATABASE_PORT=$($CUSTOMER.MYSQL_DATABASE_PORT)" `
      "MYSQL_DATABASE_DB=$($CUSTOMER.MYSQL_DATABASE_DB)" `
  | ConvertFrom-Json -Depth 10
}

$out = az_container_create_for_customer
while (!$out -or $out.provisioningState -notmatch "Succeeded") {
  Write-Host "For this operation to succeed, image has to be in ACI. Please do `make build`." -ForegroundColor Orange 
  Start-Sleep -Seconds 10
  $out = az_container_create_for_customer
}
    

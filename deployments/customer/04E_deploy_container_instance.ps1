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

az container create `
  --name "containerinstance-dummy-app" `
  --resource-group ${ARG_NAME} `
  --image ${ACI_DUMMY_IMAGE} `
  --vnet ${VNET_NAME} `
  --subnet ${VNET_SUB_ACI_NAME} `
  --environment-variables "TITLE='dummy-app'"

az container create `
--name "containerinstance-dummy" `
--resource-group ${ARG_NAME} `
--image ${ACI_DUMMY_IMAGE} `
--vnet ${VNET_NAME} `
--subnet ${VNET_SUB_ACI_NAME} `
--environment-variables "TITLE='dummy'"

echo '
# TODO fist go to vote-app-docker-compose-build-push-to-azure-container-registry
# TODO and do `bash push-images-to-azure-container-registry.sh`
# TODO has to wait for image in registry, maybe FIXME and find some smart way of waiting here
'

az acr check-health -n ${ACR_NAME} --yes

$identity=(az identity show --resource-group ${ARG_NAME} --name ${AMI_NAME}) | ConvertFrom-Json

$identityID=$identity.Id
$identityPrincipalID= $identity.principalId
$identitySecretUrl= $identity.clientSecretUrl

az container create `
  --name ${ACI_NAME} `
  --location $LOCATION `
  --resource-group ${ARG_NAME} `
  --image ${ACI_IMAGE} `
  --vnet ${VNET_NAME} `
  --subnet ${VNET_SUB_ACI_NAME} `
  --assign-identity $identityID `
  --registry-login-server "${ACR_NAME}.azurecr.io" `
  --registry-username ${AAD_ACR_PULL_CLIENT_ID} `
  --registry-password ${AAD_ACR_PULL_SECRET} `
  --environment-variables `
    "TITLE=$TITLE" `
    "MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}" `
    "MYSQL_DATABASE_PASSWORD=${MYSQL_ROOT_PASSWORD}" `
    "MYSQL_DATABASE_USER=${MYSQL_ROOT_USERNAME}" `
    "MYSQL_DATABASE_HOST=${MYSQL_DATABASE_HOST}" `
    "MYSQL_DATABASE_PORT=${MYSQL_DATABASE_PORT}" `
    "MYSQL_DATABASE_DB=${MYSQL_DATABASE_DB}"
    

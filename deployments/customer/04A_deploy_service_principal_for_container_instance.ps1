Set-StrictMode -Version Latest

. .env.ps1

echo '
#################################################################################
#### Create Service Principal used by ACI to pull from ACR
#### (Can not use AMI for cross identity during ACI pulling from ACR)
#################################################################################'

# NOTE
# Currently, services such as Azure Web App for Containers or Azure Container Instances can't use their 
# managed identity to authenticate with Azure Container Registry when pulling a container image to deploy
# the container resource itself. The identity is only available after the container is running. To deploy 
# these resources using images from Azure Container Registry, a different authentication method such as # service principal is recommended.

# DESCRIPTION: Create AKV, RBAC Service Principal. Store RBAC creds in AKV as 
#              secrets. Then create Basic ACR and ACI with ID of RBAC secrets.
#              So that ACI can access ACR via creds that it will pull from AKV.

$AAD_ACR_PULL_PRINCIPAL_NAME="${ACR_NAME}-pull"
$AAD_ACR_PULL_CLIENT_ID_NAME="${ACR_NAME}-pull-usr"
$AAD_ACR_PULL_SECRET_NAME="${ACR_NAME}-pull-pwd"

# Create service principal, store its password in AKV (the registry *password*)
$ACR_SCOPES=(az acr show --name $ACR_NAME --query id --output tsv)
$AAD_ACR_PULL_SECRET=(az ad sp create-for-rbac `
  --name $AAD_ACR_PULL_PRINCIPAL_NAME `
  --scopes $ACR_SCOPES `
  --role acrpull `
  --query password `
  --output tsv)

az keyvault secret set `
  --vault-name $AKV_NAME `
  --name $AAD_ACR_PULL_SECRET_NAME `
  --value $AAD_ACR_PULL_SECRET

# Store service principal ID in AKV (the registry *username*)
$AAD_ACR_PULL_CLIENT_ID=(az ad sp show --id http://$AAD_ACR_PULL_PRINCIPAL_NAME --query appId --output tsv)

az keyvault secret set `
    --vault-name $AKV_NAME `
    --name $AAD_ACR_PULL_CLIENT_ID_NAME `
    --value $AAD_ACR_PULL_CLIENT_ID


Set-StrictMode -Version Latest

. .env.ps1

echo '
#################################################################################
#### Save Managed Identity to AKV  
#### it will be used by ACR for encryption 
#################################################################################'

echo '
# ===============================================================================
# Get AMI
# ==============================================================================='


$identity=(az identity show --resource-group ${ARG_NAME} --name ${AMI_NAME}) | ConvertFrom-Json

$identityID=$identity.Id
$identityPrincipalID= $identity.principalId
$identitySecretUrl= $identity.clientSecretUrl

echo '
# ===============================================================================
# Set AKV policy
# ==============================================================================='


az keyvault set-policy `
  --resource-group ${ARG_NAME}  `
  --name ${AKV_NAME} `
  --object-id $identityPrincipalID `
  --key-permissions get unwrapKey wrapKey `
  --secret-permissions delete get list purge recover restore set

echo '
# ===============================================================================
# Create key in AKV
# ==============================================================================='
  
az keyvault key create `
  --name ${ACR_ENC_KEY_NAME}  `
  --vault-name ${AKV_NAME} 

echo '
# ===============================================================================
# Get key ID
# ==============================================================================='

$ACR_ENC_KEY_ID=(az keyvault key show `
  --name ${ACR_ENC_KEY_NAME} `
  --vault-name ${AKV_NAME} `
  --query 'key.kid' --output tsv)

$ACR_ENC_KEY_ID=(echo $ACR_ENC_KEY_ID | sed -e "s/\/[^/]*$//")


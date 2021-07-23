Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#### TODO secrets for ACI, use https://olegkarasik.wordpress.com/2020/04/10/using-secrets-in-azure-container-instances/

echo '
#################################################################################
#### Env Variables
#################################################################################'
$AZ_SUBS_ID="53cda94b-af20-45ab-82c0-04e260445517"

. ./powershell-scripts/scripts.ps1
Set-PsEnv ./.env.secrets

echo '
# ===============================================================================
# Internal resources
# ==============================================================================='

# TODO naming should match pattern '^[-\w\._\(\)]+$'
$UNIQUE_ID="Internal"
$LOCATION="eastus"
# resource group
$ARG_NAME="myResourceGroup-${UNIQUE_ID}" 
# storage: key vault
$AKV_NAME="myKeyVault-${UNIQUE_ID}"
# users: managed identity
$AMI_NAME="myManagedIdentity-${UNIQUE_ID}"
# computing: container registry
$ACR_NAME="myContaineRregistry${UNIQUE_ID}"
$ACR_NAME_LOW=$ACR_NAME.ToLower()
$ACR_ENC_KEY_NAME="myKeyForEncryptionOfContainerRegistry-$ACR_NAME"


Set-StrictMode -Version Latest

. ./.env.ps1

echo '
#################################################################################
#### Save Managed Identity to AKV  
#### it will be used by ACR for encryption 
#################################################################################'

echo '
# ===============================================================================
# Get AMI
# ==============================================================================='
$identity=Get-AzUserAssignedIdentity -ResourceGroupName ${ARG_NAME} -Name ${AMI_NAME}
$identity

echo "
# ===============================================================================
# Set AKV policy for identity
# ==============================================================================="


Set-AzKeyVaultAccessPolicy -BypassObjectIdValidation `
  -ResourceGroupName ${ARG_NAME}  `
  -VaultName ${AKV_NAME} `
  -ObjectId $identity.PrincipalId `
  -PermissionsToKeys get, unwrapKey, wrapKey `
  -PermissionsToSecrets delete, get, list, purge, recover, restore, set

echo '
# ===============================================================================
# Create key in AKV
# ==============================================================================='

Add-AzKeyVaultKey `
-Name ${ACR_ENC_KEY_NAME} `
-VaultName ${AKV_NAME}  `
-Destination Software



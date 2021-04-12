Set-StrictMode -Version Latest

. ./.env.ps1

echo '
# ===============================================================================
# Grant full permissions to KV to spn $Env:AAD_CLIENT_ID 
# ==============================================================================='

Set-AzKeyVaultAccessPolicy `
  -ResourceGroupName ${ARG_NAME}  `
  -VaultName ${AKV_NAME} `
  -ServicePrincipalName $Env:AAD_CLIENT_ID `
  -PermissionsToKeys backup, create, decrypt, delete, encrypt, get, import, list, purge, recover, restore, sign, unwrapKey, update, verify, wrapKey `
  -PermissionsToSecrets backup, delete, get, list, purge, recover, restore, set `
  -PermissionsToCertificates backup, create, delete, deleteissuers, get, getissuers, import, list, listissuers, managecontacts, manageissuers, purge, recover, restore, setissuers, update `
  -PermissionsToStorage backup, delete, deletesas, get, getsas, list, listsas, purge, recover, regeneratekey, restore, set, setsas, update 


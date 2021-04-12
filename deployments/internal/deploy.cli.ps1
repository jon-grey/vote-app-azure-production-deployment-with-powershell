Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. ./.env.ps1

echo "AZ_SUBS_ID=$Env:AZ_SUBS_ID"
echo "AAD_CLIENT_ID=$Env:AAD_CLIENT_ID"
echo "ADD_TENANT_ID=$Env:ADD_TENANT_ID"
echo "AAD_SECRET=$Env:AAD_SECRET"
echo "AAD_PRINCIPAL_NAME=$Env:AAD_PRINCIPAL_NAME"

echo "$Env:ACR_NAME_LOW.azurecr.io"

echo "
# ===============================================================================
# Login with Powershell
# ===============================================================================

# NOTE: Has to login with powershell and az cli seperatelly.
"


$psCredsCR = [PSCredential]::New($Env:AAD_CLIENT_ID, (ConvertTo-SecureString $Env:AAD_SECRET -AsPlainText -Force)) # Type accelerators rule!
$psCredsCR
Connect-AzAccount `
    -ServicePrincipal `
    -Credential $psCredsCR `
    -Tenant $Env:ADD_TENANT_ID `
    -Subscription $Env:AZ_SUBS_ID

Set-AzContext -Subscription $Env:AZ_SUBS_ID

echo "
# ===============================================================================
# Login with az cli
# ===============================================================================

# NOTE: Has to login with powershell and az cli seperatelly.
"
az login
# az login --service-principal --username $Env:AAD_CLIENT_ID --tenant $Env:ADD_TENANT_ID --password $Env:AAD_SECRET
az account set --subscription $Env:AZ_SUBS_ID
az account list --output table

echo "
#################################################################################
#### Begin STAGE 0: ARG
#################################################################################"
. ./00A_deploy_resource_group.ps1

echo "
#################################################################################
#### Begin STAGE 1: AMI, AKV
#################################################################################"
. ./01A_deploy_managed_identity.ps1
. ./01D_deploy_key_vault.ps1

echo "
#################################################################################
#### Begin STAGE 2: AKV Policy for self, AKV (enc) key for ACR
#################################################################################"
. ./02A_deploy_key_vault_set_policy_for_current_service_principal.ps1
. ./02A_deploy_key_vault_key_for_encryption_in_container_registry.ps1

echo "
#################################################################################
#### Begin STAGE 3: ACR
#################################################################################"
. ./03D_deploy_container_registry.ps1

echo "
#################################################################################
#### Begin STAGE 4: ASP with pulling perm from ACR
#################################################################################"
. ./04A_deploy_service_principal_for_pulling_from_container_registry.ps1




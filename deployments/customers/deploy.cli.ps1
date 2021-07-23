Set-StrictMode -Version Latest

. ./.env.ps1

echo "AZ_SUBS_ID=$Env:AZ_SUBS_ID"
echo "AAD_CLIENT_ID=$Env:AAD_CLIENT_ID"
echo "ADD_TENANT_ID=$Env:ADD_TENANT_ID"
echo "AAD_SECRET=$Env:AAD_SECRET"
echo "AAD_PRINCIPAL_NAME=$Env:AAD_PRINCIPAL_NAME"

echo "$Env:ACR_NAME_LOW.azurecr.io"

echo "
# ===============================================================================
# Login with --service-principal --username $Env:AAD_CLIENT_ID --tenant $Env:ADD_TENANT_ID --password $Env:AAD_SECRET
# ==============================================================================="

# Has to login with powershell and az cli seperatelly

$psCredsCR = [PSCredential]::New($Env:AAD_CLIENT_ID, (ConvertTo-SecureString $Env:AAD_SECRET -AsPlainText -Force)) # Type accelerators rule!
$psCredsCR
Connect-AzAccount `
    -ServicePrincipal `
    -Credential $psCredsCR `
    -Tenant $Env:ADD_TENANT_ID `
    -Subscription $Env:AZ_SUBS_ID

Set-AzContext -Subscription $Env:AZ_SUBS_ID

# Has to login with powershell and az cli seperatelly

az login --service-principal --username $Env:AAD_CLIENT_ID --tenant $Env:ADD_TENANT_ID --password $Env:AAD_SECRET
az account set --subscription $Env:AZ_SUBS_ID
az account list --output table


echo "
# #################################################################################
# #### Begin STAGE 0: ARG
# #################################################################################"
. ./00A_deploy_resource_group.ps1

echo "
# #################################################################################
# #### Begin STAGE 1: API, AVN
# #################################################################################"
. ./01B_deploy_public_ip_address.ps1
. ./01B_deploy_vnet.ps1

echo "
# #################################################################################
# #### Begin STAGE 2: ADZ, AVN Subnet for AAG and ACI, AAG
# #################################################################################"
. ./02B_deploy_public_dns_zone.ps1
. ./02B_deploy_vnet_subnet_for_app_gw.ps1
. ./02B_deploy_vnet_subnets_for_aci.ps1
# . ./02B_deploy_app_gateway.ps1

# echo "
# # #################################################################################
# # #### Begin STAGE 3
# # #################################################################################"
# . ./03B_deploy_security_group_for_subnet_aci.ps1
# . ./03B_deploy_security_group_for_subnet_app_gw.ps1
# . ./03E_deploy_container_instance.ps1

# echo "
# # #################################################################################
# # #### Begin STAGE 4
# # #################################################################################"
# . ./04B_deploy_add_container_instance_to_app_gw_backend_pool.ps1



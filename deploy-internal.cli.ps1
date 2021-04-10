Set-StrictMode -Version Latest

Set-Location ./internal

Source ./.env.ps1

#################################################################################
#### Notebook
#################################################################################

# ctrl + f `IMPORTANT`
# ctrl + f 'TODO`
# ctrl + f `NOTE`
# ctrl + f `FIXME`

#################################################################################

# . ./00A_deploy_resource_group.ps1
# . ./01A_deploy_managed_identity.ps1
# . ./01B_deploy_public_ip_address.ps1
# . ./01B_deploy_vnet_and_subnets.ps1
. ./01D_deploy_key_vault.ps1
# . ./01D_deploy_mysql_server.ps1
# . ./02B_deploy_public_dns_zone.ps1
# . ./02B_deploy_app_gateway.ps1
# . ./02B_deploy_security_groups.ps1
. ./02A_deploy_service_principal_for_container_registry.ps1
. ./02B_deploy_mysql_server_service_endpoint_to_aci_subnet.ps1
. ./03D_deploy_container_registry.ps1
. ./04A_deploy_service_principal_for_container_instance.ps1

pause "Before continuing build and push docker image to registry..."

. ./04E_deploy_container_instance.ps1
. ./05B_deploy_add_container_instance_to_app_gw_backend_pool.ps1


# # ===============================================================================
# # Get Container Group Ip
# # ===============================================================================

# # Print private IP of Container Group 
# $ACG=(Get-AzContainerGroup `
#   -Name ${ACI_NAME} `
#   -ResourceGroupName ${ARG_NAME})
# $ACG

# # Get private IP of Container Group  
# $ACI_IP=(Get-AzContainerGroup `
#   -Name ${ACI_NAME} `
#   -ResourceGroupName ${ARG_NAME}).IpAddress

# echo $ACI_IP


# #################################################################################
# #### Test App Gw public Ip pointing to customer Container Group
# #################################################################################


# # Get public IP of APP GW 
# $PUB_IP=$(az network public-ip show `
# --resource-group ${ARG_NAME} `
# --name ${PUB_IP_NAME} `
# --query [ipAddress] `
# --output tsv)

# curl $PUB_IP

# echo $PUB_IP

# echo "Go to azure portal and tweak accordingly the resources. Then download deployment of whole resource group, clean up, and ship it."
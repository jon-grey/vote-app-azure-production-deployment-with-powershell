Set-StrictMode -Version Latest

. ./.env.ps1

echo '
#################################################################################
#### Create Managed Identity
#################################################################################'

Setup-Module Az.ManagedServiceIdentity

$ManagedIdentity=Get-AzUserAssignedIdentity `
-ResourceGroupName ${ARG_NAME} `
-Name ${AMI_NAME} `
-ErrorVariable notPresent `
-ErrorAction SilentlyContinue 

if ($notPresent -or -not $ManagedIdentity) {
    New-AzUserAssignedIdentity -ResourceGroupName ${ARG_NAME} -Name  ${AMI_NAME} 
}


echo '
# ===============================================================================
# Get AMI
# ==============================================================================='
$ManagedIdentity=Get-AzUserAssignedIdentity `
    -ResourceGroupName ${ARG_NAME} `
    -Name ${AMI_NAME} 

$identityID=$ManagedIdentity.Id
$identityPrincipalID= $ManagedIdentity.principalId
$identitySecretUrl= $ManagedIdentity.clientSecretUrl

echo "identityID=$identityID"
echo "identityPrincipalID=$identityPrincipalID"
echo "identitySecretUrl=$identitySecretUrl"

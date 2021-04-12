Set-StrictMode -Version Latest

. ./.env.ps1

echo '
#################################################################################
#### Create Managed Identity
#################################################################################'

Setup-Module Az.ManagedServiceIdentity

New-AzUserAssignedIdentity -ResourceGroupName ${ARG_NAME} -Name  ${AMI_NAME} 

echo '
# ===============================================================================
# Get AMI
# ==============================================================================='
$identity=(Get-AzUserAssignedIdentity -ResourceGroupName ${ARG_NAME} -Name ${AMI_NAME} )

$identityID=$identity.Id
$identityPrincipalID= $identity.principalId
$identitySecretUrl= $identity.clientSecretUrl

echo "identityID=$identityID"
echo "identityPrincipalID=$identityPrincipalID"
echo "identitySecretUrl=$identitySecretUrl"

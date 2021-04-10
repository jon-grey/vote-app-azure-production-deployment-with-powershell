Set-StrictMode -Version Latest

. .env.ps1

echo '
#################################################################################
#### Create Managed Identity
#################################################################################'
az identity create `
--resource-group ${ARG_NAME} `
--name ${AMI_NAME}

echo '
# ===============================================================================
# Get AMI
# ==============================================================================='
$identity=(az identity show `
--resource-group ${ARG_NAME} `
--name ${AMI_NAME} `
| ConvertFrom-Json)

$identityID=$identity.Id
$identityPrincipalID= $identity.principalId
$identitySecretUrl= $identity.clientSecretUrl
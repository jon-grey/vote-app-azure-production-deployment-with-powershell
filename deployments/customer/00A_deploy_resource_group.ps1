Set-StrictMode -Version Latest

. .env.ps1

echo '
#################################################################################
#### Create Resource Group
#################################################################################'

$ResourceGroup = New-AzResourceGroup -Name ${ARG_NAME} -Location ${LOCATION}

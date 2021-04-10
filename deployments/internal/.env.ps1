Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#### TODO secrets for ACI, use https://olegkarasik.wordpress.com/2020/04/10/using-secrets-in-azure-container-instances/

echo '
#################################################################################
#### Env Variables
#################################################################################'
$SUBSCRIPTION_ID="53cda94b-af20-45ab-82c0-04e260445517"


echo '
# ===============================================================================
# Multi tenant resources
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
$ACR_NAME="mycontainerregistry${UNIQUE_ID}".ToLower()
$ACR_ENC_KEY_NAME="myKeyForEncryptionOfContainerRegistry-$ACR_NAME"

echo '
# ===============================================================================
# Helper Functions
# ==============================================================================='

function new-ipaddress {
    param (
        [string]$ip,
     
        [ValidateRange(0,255)]
        [int]$newoctet
    )
     $ip = ($ip -split '/')[0]
     $octets = $ip -split "\."
     $octets[3] = $newoctet.ToString()
     
     $newaddress = $octets -join "."
     $newaddress
}
Function pause ($message)
{
    Write-Host "$message" -ForegroundColor Yellow
    $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
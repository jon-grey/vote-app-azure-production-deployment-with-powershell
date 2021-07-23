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
"
$psCredsCR = [PSCredential]::New($Env:AAD_CLIENT_ID, (ConvertTo-SecureString $Env:AAD_SECRET -AsPlainText -Force)) # Type accelerators rule!
$psCredsCR
Connect-AzAccount `
    -ServicePrincipal `
    -Credential $psCredsCR `
    -Tenant $Env:ADD_TENANT_ID `
    -Subscription $Env:AZ_SUBS_ID

Set-AzContext -Subscription $Env:AZ_SUBS_ID

$AZ_AAD_OBJECT_ID = (Get-AzADServicePrincipal -DisplayNameBeginsWith $Env:AAD_PRINCIPAL_NAME).Id

echo "
#################################################################################
#### Begin STAGE 0: ARG
#################################################################################"
$projectName = "492233"   # This name is used to generate names for Azure resources, such as storage account name.
$location = "eastus"

if ($projectName.Length -gt 11){
    Write-Error "Variable projectName=$projectName is too long: $($projectName.Length)/11"
}

$resourceGroupName = "myResourceGroup-InternalARM"
$storageAccountName = "storeAcc-InternalARM".ToLower().replace("-","").replace("_","") # pattern: ^[a-z0-9]*$


$containerName = "arm-templates" # The name of the Blob container to be created.

$mainFileName                       = "mainTemplate.json"
$files = @(Get-ChildItem -Path arm-templates -Filter *.json -Recurse -Name)


# $mainTemplateURL = "https://raw.githubusercontent.com/Azure/azure-docs-json-samples/master/get-started-deployment/linked-template/azuredeploy.json"
# $linkedTemplateURL = "https://raw.githubusercontent.com/Azure/azure-docs-json-samples/master/get-started-deployment/linked-template/linkedStorageAccount.json"

# Download the templates
# Invoke-WebRequest -Uri $mainTemplateURL -OutFile "$home/$mainFileName"
# Invoke-WebRequest -Uri $linkedTemplateURL -OutFile "$home/$linkedFileName"

# Create a resource group

$ARG = Get-AzResourceGroup `
-Name $resourceGroupName `
-ErrorVariable notPresent `
-ErrorAction SilentlyContinue

if ($notPresent -or -not $ARG) {
    New-AzResourceGroup -Name $resourceGroupName -Location $location
}


echo "
#################################################################################
#### Begin STAGE 1: ASA
#################################################################################
[Az.Storage Module](https://docs.microsoft.com/en-us/powershell/module/az.storage/?view=azps-5.7.0#storage)
"


echo "
# ===============================================================================
# AzStorageAccount
# ===============================================================================
"
$ASA = Get-AzStorageAccount `
    -ResourceGroupName $resourceGroupName `
    -Name $storageAccountName `
    -ErrorVariable notPresent `
    -ErrorAction SilentlyContinue

echo $ASA

if ($notPresent -or -not $ASA) {
    $nameCheck = Get-AzStorageAccountNameAvailability -Name $storageAccountName

    if (!$nameCheck.NameAvailable) {
        Write-Error ( "[ERROR] Invalid storage accout name $($storageAccountName)" `
                    + "Required pattern: ^[a-z0-9]*$. Reason: $($nameCheck.Reason)." `
                    + "Message: $($nameCheck.Message)." )
    }

    # Create a storage account
    $ASA = New-AzStorageAccount `
        -ResourceGroupName $resourceGroupName `
        -Name $storageAccountName `
        -Location $location `
        -SkuName "Standard_LRS"
}


$context = $ASA.Context


echo "
# ===============================================================================
# AzStorageContainer $containerName
# ===============================================================================
"
$ASC = Get-AzStorageContainer `
    -Context $context `
    -Name $containerName `
    -ErrorVariable notPresent `
    -ErrorAction SilentlyContinue

if ($notPresent -or -not $ASC) {
    New-AzStorageContainer -Name $containerName -Context $context -Permission Container
}

# Create a container

$files.forEach({
    $fileName = $_

    echo "
    # ===============================================================================
    # AzStorageBlobContent $fileName
    # ===============================================================================
    [Set-AzStorageBlobContent (Az.Storage)](https://docs.microsoft.com/en-us/powershell/module/az.storage/set-azstorageblobcontent?view=azps-5.7.0)
    "
    Set-AzStorageBlobContent `
        -Container $containerName `
        -File "./arm-templates/$fileName" `
        -Blob $fileName `
        -Context $context `
        -Force
})


echo "
#################################################################################
#### Begin STAGE 2: 
#### AzStorageAccountKey, AzStorageContext, AzStorageContainerSASToken, 
#### AzResourceGroupDeployment
#################################################################################"

echo "
# ===============================================================================
# AzStorageAccountKey
# ===============================================================================
"
$key = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName).Value[0]

echo "
# ===============================================================================
# AzStorageContext
# ===============================================================================
"
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $key

$mainTemplateUri = $context.BlobEndPoint + "$containerName/$mainFileName"
# $mainTemplateParametersUri = $context.BlobEndPoint + "$containerName/$mainParametersFileName"

echo "
# ===============================================================================
# AzStorageContainerSASToken
# ===============================================================================
"
# A SAS token is a good way of limiting access to your templates, 
# but you should not include sensitive data like passwords directly in the template.

$sasToken = New-AzStorageContainerSASToken `
    -Context $context `
    -Container $containerName `
    -Permission r `
    -ExpiryTime (Get-Date).AddHours(2.0)
$newSas = $sasToken.substring(1)


Write-Output "mainTemplateUri=$mainTemplateUri"
# Write-Output "mainTemplateParametersUri=$mainTemplateParametersUri"


echo "
# ===============================================================================
# Create resource group.
# ===============================================================================
"
$targetResourceGroup = Get-AzResourceGroup `
    -Name "myResourceGroup-${projectName}" `
    -Location ${location} `
    -ErrorVariable deploymentError `
    -ErrorAction SilentlyContinue 

if (-not $targetResourceGroup -or $deploymentError) {
    $targetResourceGroup =  = New-AzResourceGroup -Name "myResourceGroup-${projectName}"  -Location ${location}
}

echo "
# ===============================================================================
# Validate a resource group deployment.
# ===============================================================================
[Test-AzResourceGroupDeployment (Az.Resources)](https://docs.microsoft.com/en-us/powershell/module/az.resources/test-azresourcegroupdeployment?view=azps-5.7.0)
"

# Validates a resource group deployment.
$Validation = Test-AzResourceGroupDeployment `
    -ResourceGroupName $targetResourceGroup.ResourceGroupName `
    -TemplateUri $mainTemplateUri `
    -QueryString $newSas `
    -projectName $projectName `
    -location "eastus" `
    -dnsZoneName "lubimyjedzenie.pl" `
    -currentUserServicePrincipalClientId $AZ_AAD_OBJECT_ID  `
    -Verbose

    # -TemplateParameterUri $mainTemplateParametersUri `

echo "VALIDATION: "
echo $Validation

echo "
# ===============================================================================
# Adds an Azure deployment to a resource group. 
# ===============================================================================
# [New-AzResourceGroupDeployment (Az.Resources)](https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azresourcegroupdeployment?view=azps-5.7.0)
"

$Out = New-AzResourceGroupDeployment `
  -Name DeployLinkedTemplate `
  -ResourceGroupName $targetResourceGroup.ResourceGroupName `
  -TemplateUri $mainTemplateUri `
  -QueryString $newSas `
  -projectName $projectName `
  -location "eastus" `
  -dnsZoneName "lubimyjedzenie.pl" `
  -currentUserServicePrincipalClientId $AZ_AAD_OBJECT_ID  `
  -ErrorVariable deploymentError `
  -ErrorAction SilentlyContinue `
  -Verbose

#   -Verbose `
#   -TemplateParameterUri $mainTemplateParametersUri `
sleep 1

Write-Host "Deployment output: "

$Out | ConvertTo-Json -Depth 100

Write-Host "==================="


if ($deploymentError -or -not $Out){
    $deploymentError 
    Write-Error "Deployment FAILED."
}

sleep 5
# New-AzResourceGroupDeployment: /home/W/W.b2b/azure/pocs/vote-app-azure-production-deployment-with-powershell/deployments/internal-arm/deploy.cli.ps1:187:1
# Line |
#  187 |  New-AzResourceGroupDeployment `
#      |  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#      | 1:21:18 PM - Error: Code=InvalidTemplateDeployment; Message=The template deployment 'DeployLinkedTemplate' is not valid according to the validation procedure. The tracking id is
#      | '71074688-5fea-490a-9172-ae34fe341e1c'. See inner errors for details.

# Get-AzLog -CorrelationId 71074688-5fea-490a-9172-ae34fe341e1c -DetailedOutput
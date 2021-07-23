@minLength(3)
@maxLength(24)
@description('Specify the storage account name.')
param storageAccountName string

@description('Specify a location for the resources.')
param location string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
@description('Specify the storage account type.')
param storageSKU string = 'Standard_LRS'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2021-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageSKU
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
}

output storageEndpoint object = reference(storageAccountName).primaryEndpoints
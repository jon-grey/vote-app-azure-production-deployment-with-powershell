@description('Specify a Service Plan name for the app.')
param appServicePlanName string
param location string

resource appServicePlanName_resource 'Microsoft.Web/serverfarms@2020-09-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
    size: 'B1'
    family: 'B'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    perSiteScaling: false
    reserved: true
    targetWorkerCount: 0
    targetWorkerSizeId: 0
  }
}

output resourceID string = appServicePlanName_resource.id
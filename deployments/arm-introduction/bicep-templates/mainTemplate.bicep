@minLength(3)
@maxLength(11)
@description('Specify a project name that is used to generate resource names.')
param projectName string

@allowed([
  'southcentralus'
  'westus'
  'centralus'
  'eastus'
  'northcentralus'
  'westcentralus'
])
@description('Specify a location for the resources.')
param location string = 'eastus'

@description('The Runtime stack of current web app')
param linuxFxVersion string = 'php|7.0'
param resourceTags object = {
  Environment: 'Dev'
  Project: projectName
}

var storageAccountName = toLower('storageAcc${uniqueString(resourceGroup().id)}')
var webAppName = 'webApp-${projectName}'
var appServicePlanName = 'servicePlan-${projectName}'

module deploymentStorageAccount 'az.arm-template.deploy.storage-account.bicep' = {
  name: 'deploymentStorageAccount'
  params: {
    storageAccountName: storageAccountName
    location: location
  }
}

module deploymentAppServicePlan 'az.arm-template.deploy.app.service-plan.bicep' = {
  name: 'deploymentAppServicePlan'
  params: {
    appServicePlanName: appServicePlanName
    location: location
  }
  dependsOn: [
    deploymentStorageAccount
  ]
}

module deploymentWebApp 'az.arm-template.deploy.app.web-app.bicep' = {
  name: 'deploymentWebApp'
  params: {
    webAppName: webAppName
    appServicePlanId: reference('deploymentAppServicePlan').outputs.resourceID.value
    location: location
    linuxFxVersion: linuxFxVersion
  }
  dependsOn: [
    deploymentStorageAccount
    deploymentAppServicePlan
  ]
}

output storageEndpoint object = reference('deploymentStorageAccount').outputs.storageEndpoint.value
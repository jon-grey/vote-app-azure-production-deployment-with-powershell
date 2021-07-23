@description('Specify a Web App name.')
param webAppName string

@description('Specify a App Service Plan ID.')
param appServicePlanId string
param location string

@description('The Runtime stack of current web app.')
param linuxFxVersion string = 'php|7.0'

resource webAppName_resource 'Microsoft.Web/sites@2020-12-01' = {
  name: webAppName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: linuxFxVersion
    }
  }
}
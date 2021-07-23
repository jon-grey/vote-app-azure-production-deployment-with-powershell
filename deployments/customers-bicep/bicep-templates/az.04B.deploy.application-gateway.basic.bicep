/*****************************************************************************************
**** Required parameters
*****************************************************************************************/
@description('App Gw Name, ie. appGw') 
param appGwName string

@description('Vnet name, ie. vnet.')
param vnetName string

@description('Vnet subnet name, ie. subnetAAG.')
param subnetName string

@description('Tags - look at best practices.')
param resourceTags object

@description('Subnet IP Address, ie. 10.0.0.0/24')
param subnetAddress string 

@description('Public address used by App Gw Frontend belonging to provided subnet, ie. 10.0.0.10')
param privateIPAddress string 

@description('Public address used by App Gw Frontend, ie. myPublicIp_appGw')
param publicIPAddressName string 

@description('App Gw User Assigned Identity ID, ie. AMI ID.')
param userAssignedIdentityId string 

/*****************************************************************************************
**** Optionally required parameters
*****************************************************************************************/
@description('Sku Name')
@allowed([
  'Standard_Small'
  'Standard_Medium'
  'Standard_Large'
  'Standard_v2'
  'WAF_Large' 
  'WAF_Medium'
  'WAF_v2'
])
param skuName string = 'Standard_v2'

@description('Sku Tier')
@allowed([
  'Standard'
  'Standard_v2'
  'WAF'
  'WAF_v2'
])
param skuTier string = 'Standard_v2'

@description('Number of instances')
param capacity int = 1

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Port used by App Gw frontend.')
param appGwFrontendPort int = 80

@description('Protocol used by App Gw frontend.')
param appGwFrontendProtocol string = 'Http'

/*****************************************************************************************
**** Variables
*****************************************************************************************/
var m_httpListeners = [
  {
    name: 'appGwHttpListener${appGwFrontendProtocol}${appGwFrontendPort}'
    protocol: appGwFrontendProtocol
    hostName: json('null')
  }
]
var m_backendPools = [
  {
    name: 'appGwBackendPool${appGwFrontendProtocol}${appGwFrontendPort}'
    properties: {
      backendAddresses: []
    }
  }
]
var m_backendHttpSettingsCollection = [
  {
    name: 'appGwBackendHttpSettings${appGwFrontendProtocol}${appGwFrontendPort}'
    properties: {
      port: appGwFrontendPort
      protocol: appGwFrontendProtocol
      cookieBasedAffinity: 'Disabled'
      pickHostNameFromBackendAddress: false
      requestTimeout: 30
    }
  }
]
var m_requestRoutingRules = [
  {
    name: 'appGwRoutingRule${appGwFrontendProtocol}${appGwFrontendPort}'
    httpListener: last(m_httpListeners).name
    backendAddressPool: last(m_backendPools).name
    backendHttpSettings: last(m_backendHttpSettingsCollection).name
  }
]

/*****************************************************************************************
**** Deployment
*****************************************************************************************/

module deploymentAppGwBasic 'az.04B.deploy.application-gateway.bicep' = {
  name: 'deploymentAppGwBasic'
  params: {
    appGwName : appGwName
    skuName: skuName
    skuTier: skuTier
    capacity: capacity
    location: location
    vnetName: vnetName
    subnetName: subnetName
    resourceTags: resourceTags
    subnetAddress: subnetAddress
    publicIPAddressName: publicIPAddressName
    privateIPAddress: privateIPAddress
    appGwFrontendPort: appGwFrontendPort
    backendPools: m_backendPools
    httpListeners: m_httpListeners
    requestRoutingRules: m_requestRoutingRules
    backendHttpSettingsCollection: m_backendHttpSettingsCollection
    userAssignedIdentityId: userAssignedIdentityId
    // appServicePlanId: reference('deploymentAppServicePlan').outputs.resourceID.value
  }
}

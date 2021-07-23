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
**** Customer required parameters
*****************************************************************************************/
@description('Dns zone name, ie. lubimyjedzenie.pl')
param dnsZoneName string

@description('Sub dns zone name for customers, ie. app.lubimyjedzenie.pl')
param subDnsZoneName string

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
var m_backendPools = [
  {
    name: 'appGwBackendPool${appGwFrontendProtocol}${appGwFrontendPort}DummyApp'
    properties: {
      backendAddresses: []
    }
  }
  {
    name: 'appGwBackendPool${appGwFrontendProtocol}${appGwFrontendPort}Dummy'
    properties: {
      backendAddresses: []
    }
  }
  {
    name: 'appGwBackendPool${appGwFrontendProtocol}${appGwFrontendPort}'
    properties: {
      backendAddresses: []
    }
  }
]
var m_backendHttpSettingsCollection = [
  {
    name: 'appGwBackendHttpSettings${appGwFrontendProtocol}${appGwFrontendPort}DummyApp'
    properties: {
      port: appGwFrontendPort
      protocol: appGwFrontendProtocol
      cookieBasedAffinity: 'Disabled'
      hostName: subDnsZoneName
      pickHostNameFromBackendAddress: false
      requestTimeout: 30
    }
  }
  {
    name: 'appGwBackendHttpSettings${appGwFrontendProtocol}${appGwFrontendPort}Dummy'
    properties: {
      port: appGwFrontendPort
      protocol: appGwFrontendProtocol
      cookieBasedAffinity: 'Disabled'
      hostName: dnsZoneName
      pickHostNameFromBackendAddress: false
      requestTimeout: 30
    }
  }
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
var m_httpListeners = [
  {
    name: 'appGwHttpListener${appGwFrontendProtocol}${appGwFrontendPort}DummyApp'
    protocol: appGwFrontendProtocol
    hostName: subDnsZoneName
  }
  {
    name: 'appGwHttpListener${appGwFrontendProtocol}${appGwFrontendPort}Dummy'
    protocol: appGwFrontendProtocol
    hostName: dnsZoneName
  }
  {
    name: 'appGwHttpListener${appGwFrontendProtocol}${appGwFrontendPort}'
    protocol: appGwFrontendProtocol
    hostName: json('null')
  }
]
var m_requestRoutingRules = [
  {
    name: 'appGwRoutingRule${appGwFrontendProtocol}${appGwFrontendPort}DummyApp'
    httpListener: m_httpListeners[0].name
    backendAddressPool: m_backendPools[0].name
    backendHttpSettings: m_backendHttpSettingsCollection[0].name
  }
  {
    name: 'appGwRoutingRule${appGwFrontendProtocol}${appGwFrontendPort}Dummy'
    httpListener: m_httpListeners[1].name
    backendAddressPool: m_backendPools[1].name
    backendHttpSettings: m_backendHttpSettingsCollection[1].name
  }
  {
    name: 'appGwRoutingRule${appGwFrontendProtocol}${appGwFrontendPort}'
    httpListener: m_httpListeners[2].name
    backendAddressPool: m_backendPools[2].name
    backendHttpSettings: m_backendHttpSettingsCollection[2].name
  }
]

/*****************************************************************************************
**** Deployment
*****************************************************************************************/
module deploymentAppGwDummy 'az.04B.deploy.application-gateway.bicep' = {
  name: 'deploymentAppGwDummy'
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
    // appServicePlanId: reference('deploymentAppServicePlan').outputs.resourceID.value // example of implicit dependency, require deployment in current deployments
  }
}

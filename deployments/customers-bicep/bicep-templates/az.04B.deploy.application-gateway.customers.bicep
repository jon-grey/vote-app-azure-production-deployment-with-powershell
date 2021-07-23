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

@description('Customers routing rules, listeners, backend pools to preallocate.')
@maxValue(97) // 100 is max: 97 is for customers, 1 for basic, 1 for dummy, 1 for dummyApp
@minValue(0)
param customersCount int

@description('Array of customers data.')
param customers array

@description('Array of customer backend pool servers')
param customersBackendPoolServers array = []
/*****************************************************************************************
**** Dummy required parameters
*****************************************************************************************/
@description('Array of dummy backend pool servers')
param dummyBackendPoolServers array = []

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

var m_backendPoolsCustomers = [for i in range(0,customersCount): {
  name: '${last(m_backendPoolsBasic).name}Customer${customers[i].id}'
  properties: {
    backendAddresses: [] // customersBackendPoolServers[customers[i].id]
  }
}]

var m_httpListenersCustomers = [for i in range(0,customersCount): {
  name:     '${last(m_httpListenersBasic).name}Customer${customers[i].id}'
  protocol: 'Http'
  hostName: '${customers[i].id}.${subDnsZoneName}'
}]

var m_requestRoutingRulesCustomers = [for i in range(0,customersCount): {
  name:                 '${last(m_requestRoutingRulesBasic).name}Customer${customers[i].id}'
  httpListener:         '${last(m_httpListenersBasic).name}Customer${customers[i].id}'
  backendAddressPool:   '${last(m_backendPoolsBasic).name}Customer${customers[i].id}'
  backendHttpSettings:    first(m_backendHttpSettingsCollection).name
}]

var m_backendPoolsBasic = [
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

var m_httpListenersBasic = [
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
var m_requestRoutingRulesBasic = [
  {
    name: 'appGwRoutingRule${appGwFrontendProtocol}${appGwFrontendPort}DummyApp'
    httpListener: m_httpListenersBasic[0].name
    backendAddressPool: m_backendPoolsBasic[0].name
    backendHttpSettings: m_backendHttpSettingsCollection[0].name
  }
  {
    name: 'appGwRoutingRule${appGwFrontendProtocol}${appGwFrontendPort}Dummy'
    httpListener: m_httpListenersBasic[1].name
    backendAddressPool: m_backendPoolsBasic[1].name
    backendHttpSettings: m_backendHttpSettingsCollection[1].name
  }
  {
    name: 'appGwRoutingRule${appGwFrontendProtocol}${appGwFrontendPort}'
    httpListener: m_httpListenersBasic[2].name
    backendAddressPool: m_backendPoolsBasic[2].name
    backendHttpSettings: m_backendHttpSettingsCollection[2].name
  }
]

var m_backendHttpSettingsCollection = [
  {
    name: 'appGwBackendHttpSettings${appGwFrontendProtocol}${appGwFrontendPort}Customers'
    properties: {
      port: appGwFrontendPort
      protocol: appGwFrontendProtocol
      cookieBasedAffinity: 'Disabled'
      hostName: '*.${subDnsZoneName}'
      pickHostNameFromBackendAddress: false
      requestTimeout: 30
    }
  }
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

var m_backendPools = concat(m_backendPoolsCustomers, m_backendPoolsBasic)
var m_httpListeners = concat(m_httpListenersCustomers, m_httpListenersBasic)
var m_requestRoutingRules = concat(m_requestRoutingRulesCustomers, m_requestRoutingRulesBasic)

/*****************************************************************************************
**** Deployment
*****************************************************************************************/
module deploymentAppGwCustomers 'az.04B.deploy.application-gateway.bicep' = {
  name: 'deploymentAppGwCustomers'
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

output outputs object = {
  httpListeners: m_httpListeners
  backendPools: m_backendPools
  requestRoutingRules: m_requestRoutingRules
}

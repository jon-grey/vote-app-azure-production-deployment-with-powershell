@description('App Gw Name')
param appGwName string

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
param skuName string // = 'Standard_v2'

@description('Sku Tier')
@allowed([
  'Standard'
  'Standard_v2'
  'WAF'
  'WAF_v2'
])
param skuTier string // = 'Standard_v2'

@description('Number of instances')
param capacity int // = 1

@description('Location for all resources.')
param location string // = resourceGroup().location

@description('Vnet name.')
param vnetName string

@description('Vnet subnet name.')
param subnetName string

@description('Tags.')
param resourceTags object // = {}

@description('Tags.')
param subnetAddress string // = '10.0.0.0/24'

@description('Public address used by App Gw Frontend.')
param publicIPAddressName string // = 'myPublicIp_${appGwName}'

@description('Public address used by App Gw Frontend belonging to provided subnet.')
param privateIPAddress string // = '10.0.0.10'

@description('Port used by App Gw frontend.')
param appGwFrontendPort int // = 80

@description('App Gw backend pools holding IP addresses of customer ACI.')
param backendPools array

@description('App Gw http listeners for catching domain requests.')
param httpListeners array

@description('App Gw request routing rules from listeners to backend pools.')
param requestRoutingRules array

@description('App Gw settings for routing rules: port, protocol, cookie affinity.')
param backendHttpSettingsCollection array

@description('App Gw User Assigned Identity, ie. AMI.')
param userAssignedIdentityId string // = '/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourcegroups/myResourceGroup-InternalARM/providers/Microsoft.ManagedIdentity/userAssignedIdentities/managedIdentity-InternalARM'

resource deploymentAppGw 'Microsoft.Network/applicationGateways@2020-11-01' = {
  name: appGwName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    urlPathMaps: []
    probes: []
    rewriteRuleSets: []
    redirectConfigurations: []
    privateLinkConfigurations: []
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 3
    }
    customErrorConfigurations: []
    sku: {
      name: skuName
      tier: skuTier
    }
    gatewayIPConfigurations: [
      {
        name: '${appGwName}_IpConfig_${subnetName}'
        properties: {
          subnet: {
            id: '${resourceGroup().id}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${subnetName}'
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIP'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: '${resourceGroup().id}/providers/Microsoft.Network/publicIPAddresses/${publicIPAddressName}'
          }
        }
      }
      {
        name: 'appGwPrivateFrontendIP'
        properties: {
          privateIPAddress: '${privateIPAddress}'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: '${resourceGroup().id}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${subnetName}'
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGwFrontendPort${appGwFrontendPort}'
        properties: {
          port: appGwFrontendPort
        }
      }
    ]
    backendAddressPools: backendPools
    backendHttpSettingsCollection: backendHttpSettingsCollection
    
    
    httpListeners: [for item in httpListeners: {
      name: item.name
      properties: {
        frontendIPConfiguration: {
          // id: '${appGwName_resource.id}/frontendIPConfigurations/appGwPublicFrontendIP'
          id: '${resourceId('Microsoft.Network/applicationGateways/', appGwName)}/frontendIPConfigurations/appGwPublicFrontendIP'
        }
        frontendPort: {
          // id: '${appGwName_resource.id}/frontendPorts/appGwFrontendPort${appGwFrontendPort}'
          id: '${resourceId('Microsoft.Network/applicationGateways/', appGwName)}/frontendPorts/appGwFrontendPort${appGwFrontendPort}'
        }
        protocol: item.protocol
        hostName: item.hostName
        hostNames: []
        requireServerNameIndication: false
        customErrorConfigurations: []
      }
    }]
    requestRoutingRules: [for item in requestRoutingRules: {
      name: item.name
      properties: {
        ruleType: 'Basic'
        httpListener: {
          // id: '${appGwName_resource.id}/httpListeners/${item.httpListener}'
          id: '${resourceId('Microsoft.Network/applicationGateways/', appGwName)}/httpListeners/${item.httpListener}'
        }
        backendAddressPool: {
          // id: '${appGwName_resource.id}/backendAddressPools/${item.backendAddressPool}'
          id: '${resourceId('Microsoft.Network/applicationGateways/', appGwName)}/backendAddressPools/${item.backendAddressPool}'
        }
        backendHttpSettings: {
          // id: '${appGwName_resource.id}/backendHttpSettingsCollection/${item.backendHttpSettings}'
          id: '${resourceId('Microsoft.Network/applicationGateways/', appGwName)}/backendHttpSettingsCollection/${item.backendHttpSettings}'
        }
      }
    }]
  }
  dependsOn: []
}

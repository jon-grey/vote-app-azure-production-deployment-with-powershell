/*****************************************************************************************
**** Globally Required parameters
*****************************************************************************************/
@description('Suffix of current resource group, range [0, 800 - managementGroups]')
param resourceGroupSuffix string

@description('Suffix of current resource group customers chunk, ~ 90-99 customers per chunk') 
param customersChunkSuffix string

/*****************************************************************************************
**** App Gw Required parameters
*****************************************************************************************/
@description('App Gw Name, ie. appGw-000-000, 1000 App Gw per subscription, 100 rules per App Gw') 
param appGwName string = 'myAppGw-${resourceGroupSuffix}' //-${customersChunkSuffix}

@description('Vnet name, ie. vnet, 1000 per subscription.')
param vnetName string = 'myVNet-${resourceGroupSuffix}'

@description('Vnet subnet name, ie. subnetAAG, 3000 per vnet.')
param subnetName string = 'subnetAAG' //-${appGwName}'

@description('Tags - look at best practices.')
param resourceTags object = {}

@description('Subnet IP Address, ie. 10.0.0.0/24')
param subnetAddress string = '10.0.0.0/24'

@description('Public address used by App Gw Frontend belonging to provided subnet, ie. 10.0.0.10')
param privateIPAddress string = '10.0.0.10'

@description('Public address used by App Gw Frontend, ie. myPublicIp_appGw')
param publicIPAddressName string = 'myPublicIp_${appGwName}'

@description('App Gw User Assigned Identity ID, ie. AMI ID.')
param userAssignedIdentityId string = '/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourcegroups/myResourceGroup-InternalARM/providers/Microsoft.ManagedIdentity/userAssignedIdentities/managedIdentity-InternalARM'

/*****************************************************************************************
**** App Gw Customer required parameters
*****************************************************************************************/
@description('Dns zone name, ie. lubimyjedzenie.pl')
param dnsZoneName string = 'lubimyjedzenie.pl'

@description('Sub dns zone name for customers, ie. app.lubimyjedzenie.pl')
param subDnsZoneName string = 'app.${dnsZoneName}'

@description('Customers routing rules, listeners, backend pools to preallocate.')
@maxValue(97) // 100 is max: 97 is for customers, 1 for basic, 1 for dummy, 1 for dummyApp
@minValue(0)
param customersCount int = 2

@description('Next customers ID prefix string.')
param lastCustomerId int = 2120

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

var customers = [for i in range(0,customersCount): {
  id: format('{0:D9}', lastCustomerId + i) 
}]


/*****************************************************************************************
**** Deployment
*****************************************************************************************/

// // deployments/customers/01B_deploy_public_ip_address.ps1
// module deploymentPublicIpAddress 'az.01B.deploy.public-ip-address.customers.bicep' = {
//   name: 'deploymentPublicIpAddress'
//   params: {
//   }
// }

// // deployments/customers/01B_deploy_vnet.ps1
// // deployments/customers/02B_deploy_vnet_subnet_for_app_gw.ps1
// // deployments/customers/02B_deploy_vnet_subnets_for_aci.ps1
// module deploymentVnet 'az.01B.deploy.virtual-network.with-subnets.bicep' = {
//   name: 'deploymentVnet'
//   params: {
//     customers: customers
//   }
// }

// // deployments/customers/02B_deploy_public_dns_zone.ps1
// module deploymentPublicDnsZone 'az.02B.deploy.public-dns-zone.customers.bicep' = {
//   name: 'deploymentPublicDnsZone'
//   dependsOn: [
//     deploymentPublicIpAddress
//   ]
//   params: {
//     publicIp: deploymentPublicIpAddress.outputs.publicIp
//   }
// }

// // deployments/customers/03B_deploy_security_group_for_subnet_app_gw.ps1
// module deploymentSecGroupForAppGw 'az.03B.deploy.security-group.for-subnet.app-gw.bicep' = {
//   name: 'deploymentSecGroupForAppGw'
//   dependsOn : [
//     deploymentVnet
//   ]
//   params: {
//     vnetId: 
//     subnetId: // appGwSubnet
//   }
// }

// // deployments/customers/03B_deploy_security_group_for_subnet_aci.ps1
// module deploymentSecGroupForAci 'az.03B.deploy.security-group.for-subnet.aci.bicep' = {
//   name: 'deploymentSecGroupForAci'
//   dependsOn : [
//     deploymentVnet
//   ]
//   params: {
//     customers: customers
//     vnetId: 
//     subnetsId : // aci subnets
//   }
// }

// // deployments/customers/03E_deploy_container_instance.ps1
// module deploymentContainerGroupDummy 'az.03E.deploy.container-group.dummy.bicep' = {
//   name: 'deploymentContainerGroupDummy'
//   dependsOn : [
//     deploymentVnet
//   ]
//   params: {
//     vnetId:
//     subnetId: 

//   }

// }


// deployments/customers/02B_deploy_app_gateway.ps1
// deployments/customers/04B_deploy_add_container_instance_to_app_gw_backend_pool.ps1
module deploymentAppGwCustomers 'az.04B.deploy.application-gateway.customers.bicep' = {
  name: 'deploymentAppGwCustomers'
  dependsOn: [
    // deploymentVnet
    // deploymentPublicIpAddress
    // deploymentPublicDnsZone
    // deploymentSecGroupForAppGw
    // deploymentSecGroupForAci 
  ]
  params: {
    // required params for app gw functioning
    appGwName : appGwName
    vnetName: vnetName
    subnetName: subnetName
    resourceTags: resourceTags
    subnetAddress: subnetAddress
    privateIPAddress: privateIPAddress
    publicIPAddressName: publicIPAddressName
    userAssignedIdentityId: userAssignedIdentityId
    // required params for routing dummy and customers
    dnsZoneName: dnsZoneName
    subDnsZoneName: subDnsZoneName
    customersCount: customersCount
    // optional params for app gw tweaking
    skuName: skuName
    skuTier: skuTier
    capacity: capacity
    location: location
    appGwFrontendPort: appGwFrontendPort
    appGwFrontendProtocol: appGwFrontendProtocol
    // backend pool servers list of ACI private IP addresses
    customers: customers
    customersBackendPoolServers: []
    dummyBackendPoolServers: reference('deploymentContainerGroupDummy').outputs.ipAddresses
    // appServicePlanId: reference('deploymentAppServicePlan').outputs.resourceID.value // example of implicit dependency, require deployment in current deployments
  }
}

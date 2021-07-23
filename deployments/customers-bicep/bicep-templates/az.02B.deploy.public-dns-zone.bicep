/*
https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-05-01/dnszones?tabs=bicep#property-values

deployments/customers/02B_deploy_public_dns_zone.ps1
*/


resource symbolicname 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: 'string'
  location: 'string'
  tags: {}
  properties: {
    zoneType: 'string'
    registrationVirtualNetworks: [
      {
        id: 'string'
      }
    ]
    resolutionVirtualNetworks: [
      {
        id: 'string'
      }
    ]
  }
  resources: []
}

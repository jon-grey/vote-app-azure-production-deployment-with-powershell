/*
https://docs.microsoft.com/en-us/azure/templates/microsoft.network/publicipaddresses?tabs=json#property-values

deployments/customers/01B_deploy_public_ip_address.ps1

*/

resource symbolicname 'Microsoft.Network/publicIPAddresses@2020-07-01' = {
  name: 'string'
  location: 'string'
  tags: {}
  extendedLocation: {
    name: 'string'
    type: 'EdgeZone'
  }
  sku: {
    name: 'string'
    tier: 'string'
  }
  properties: {
    publicIPAllocationMethod: 'string'
    publicIPAddressVersion: 'string'
    dnsSettings: {
      domainNameLabel: 'string'
      fqdn: 'string'
      reverseFqdn: 'string'
    }
    ddosSettings: {
      ddosCustomPolicy: {
        id: 'string'
      }
      protectionCoverage: 'string'
      protectedIP: bool
    }
    ipTags: [
      {
        ipTagType: 'string'
        tag: 'string'
      }
    ]
    ipAddress: 'string'
    publicIPPrefix: {
      id: 'string'
    }
    idleTimeoutInMinutes: int
  }
  zones: [
    'string'
  ]
}

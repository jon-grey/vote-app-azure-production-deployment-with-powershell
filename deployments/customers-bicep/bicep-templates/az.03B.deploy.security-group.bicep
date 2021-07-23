resource symbolicname 'Microsoft.Network/networkSecurityGroups@2020-07-01' = {
  name: 'string'
  location: 'string'
  tags: {}
  properties: {
    securityRules: [
      {
        id: 'string'
        properties: {
          description: 'string'
          protocol: 'string'
          sourcePortRange: 'string'
          destinationPortRange: 'string'
          sourceAddressPrefix: 'string'
          sourceAddressPrefixes: [
            'string'
          ]
          sourceApplicationSecurityGroups: [
            {
              id: 'string'
              location: 'string'
              tags: {}
              properties: {}
            }
          ]
          destinationAddressPrefix: 'string'
          destinationAddressPrefixes: [
            'string'
          ]
          destinationApplicationSecurityGroups: [
            {
              id: 'string'
              location: 'string'
              tags: {}
              properties: {}
            }
          ]
          sourcePortRanges: [
            'string'
          ]
          destinationPortRanges: [
            'string'
          ]
          access: 'string'
          priority: int
          direction: 'string'
        }
        name: 'string'
      }
    ]
  }
  resources: []
}

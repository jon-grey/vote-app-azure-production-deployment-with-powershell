resource symbolicname 'Microsoft.Network/virtualNetworks@2020-07-01' = {
  name: 'string'
  location: 'string'
  tags: {}
  extendedLocation: {
    name: 'string'
    type: 'EdgeZone'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        'string'
      ]
    }
    dhcpOptions: {
      dnsServers: [
        'string'
      ]
    }
    subnets: [
      {
        id: 'string'
        properties: {
          addressPrefix: 'string'
          addressPrefixes: [
            'string'
          ]
          networkSecurityGroup: {
            id: 'string'
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
          }
          routeTable: {
            id: 'string'
            location: 'string'
            tags: {}
            properties: {
              routes: [
                {
                  id: 'string'
                  properties: {
                    addressPrefix: 'string'
                    nextHopType: 'string'
                    nextHopIpAddress: 'string'
                  }
                  name: 'string'
                }
              ]
              disableBgpRoutePropagation: bool
            }
          }
          natGateway: {
            id: 'string'
          }
          serviceEndpoints: [
            {
              service: 'string'
              locations: [
                'string'
              ]
            }
          ]
          serviceEndpointPolicies: [
            {
              id: 'string'
              location: 'string'
              tags: {}
              properties: {
                serviceEndpointPolicyDefinitions: [
                  {
                    id: 'string'
                    properties: {
                      description: 'string'
                      service: 'string'
                      serviceResources: [
                        'string'
                      ]
                    }
                    name: 'string'
                  }
                ]
              }
            }
          ]
          ipAllocations: [
            {
              id: 'string'
            }
          ]
          delegations: [
            {
              id: 'string'
              properties: {
                serviceName: 'string'
              }
              name: 'string'
            }
          ]
          privateEndpointNetworkPolicies: 'string'
          privateLinkServiceNetworkPolicies: 'string'
        }
        name: 'string'
      }
    ]
    virtualNetworkPeerings: [
      {
        id: 'string'
        properties: {
          allowVirtualNetworkAccess: bool
          allowForwardedTraffic: bool
          allowGatewayTransit: bool
          useRemoteGateways: bool
          remoteVirtualNetwork: {
            id: 'string'
          }
          remoteAddressSpace: {
            addressPrefixes: [
              'string'
            ]
          }
          remoteBgpCommunities: {
            virtualNetworkCommunity: 'string'
          }
          peeringState: 'string'
        }
        name: 'string'
      }
    ]
    enableDdosProtection: bool
    enableVmProtection: bool
    ddosProtectionPlan: {
      id: 'string'
    }
    bgpCommunities: {
      virtualNetworkCommunity: 'string'
    }
    ipAllocations: [
      {
        id: 'string'
      }
    ]
  }
  resources: []
}

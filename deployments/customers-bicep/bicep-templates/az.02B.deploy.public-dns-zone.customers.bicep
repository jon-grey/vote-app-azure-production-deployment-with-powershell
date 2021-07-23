/*
https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-05-01/dnszones?tabs=bicep#property-values

deployments/customers/02B_deploy_public_dns_zone.ps1
*/

module deploymentPublicDnsZoneOuter 'az.02B.deploy.public-dns-zone.bicep' = {
  name: 'deploymentPublicDnsZoneOuter'
  dependsOn: []
  params: {

  }

}


module deploymentPublicDnsZoneInner 'az.02B.deploy.public-dns-zone.bicep' = {
  name: 'deploymentPublicDnsZoneInner'
  dependsOn: [
    deploymentPublicDnsZoneOuter
  ]
  params: {

  }

}


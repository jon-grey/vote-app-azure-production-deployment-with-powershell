

# App Gw

[Azure security baseline for Application Gateway](https://docs.microsoft.com/en-us/azure/application-gateway/security-baseline)

# Usefull powershell

## Null coalescing

```ps1
PS /home/robert> $null ?? 100
100
```

# Data from proper setup

```ps1

# PUBLIC IP

Get-AzPublicIpAddress `
  -ResourceGroupName ${ARG_NAME} `
  -Name ${PUB_IP_NAME} 

Name                     : myPublicIpAppGw
ResourceGroupName        : myResourceGroup004
Location                 : westeurope
Id                       : /subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myResourceGroup004/providers/Microsoft.Network/publicIPAddresses/myPublicIpAppGw
Etag                     : W/"84518431-4aea-4f0d-8cb0-0898b26a271b"
ResourceGuid             : bc80f4a8-a625-4a0e-b601-994b961818eb
ProvisioningState        : Succeeded
Tags                     :
PublicIpAllocationMethod : Static
IpAddress                : 51.144.121.121
PublicIpAddressVersion   : IPv4
IdleTimeoutInMinutes     : 4
IpConfiguration          : {
                             "Id": "/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myResourceGroup004/providers
                           /Microsoft.Network/applicationGateways/myAppGw/frontendIPConfigurations/appGwPublicFrontendIp"
                           }
DnsSettings              : {
                             "DomainNameLabel": "lubimyjedzenie",
                             "Fqdn": "lubimyjedzenie.westeurope.cloudapp.azure.com"
                           }
Zones                    : {}
Sku                      : {
                             "Name": "Standard",
                             "Tier": "Regional"
                           }
IpTags                   : []


$PublicIp = New-AzPublicIpAddress `
  -ResourceGroupName ${ARG_NAME} `
  -Name ${PUB_IP_NAME} `
  -Location ${LOCATION} `
  -AllocationMethod "Dynamic" `
  -Sku Basic `
  -Tier Regional `
  -DomainNameLabel ${DNS_ZONE_NAME}.Split('.')[0]

# DNS ZONE

Get-AzDnsZone   -Name ${DNS_ZONE_NAME}  -ResourceGroupName ${ARG_NAME}

Name                          : lubimyjedzenie.pl
ResourceGroupName             : myresourcegroup004
Etag                          : 00000002-0000-0000-9360-4094ba2cd701
Tags                          : {}
NameServers                   : {ns1-01.azure-dns.com., ns2-01.azure-dns.net., ns3-01.azure-dns.org., ns4-01.azure-dns.info.}
ZoneType                      : Public
RegistrationVirtualNetworkIds : {}
ResolutionVirtualNetworkIds   : {}
NumberOfRecordSets            : 3
MaxNumberOfRecordSets         : 10000

New-AzDnsZone  -Name ${DNS_ZONE_NAME}   -ResourceGroupName ${ARG_NAME} -ZoneType Public 

# DNS ZONE Record A Name *

Get-AzDnsRecordSet    -ZoneName ${DNS_ZONE_NAME}   -ResourceGroupName ${ARG_NAME} -Name '*' -RecordType A


Id                : /subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myResourceGroup004/providers/Microsoft.Network/dnszones/lubimyjedzenie.pl/A/*
Name              : *
ZoneName          : lubimyjedzenie.pl
ResourceGroupName : myResourceGroup004
Ttl               : 3600
Etag              : 13aec85a-0802-430f-a29c-3c35073b2dc8
RecordType        : A
TargetResourceId  : /subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myResourceGroup004/providers/Microsoft.Network/publicIPAddresses/myPublicIpAppGw
Records           : {}
Metadata          :
ProvisioningState : Succeeded



New-AzDnsRecordSet `
  -Name '*' `
  -RecordType A `
  -Ttl 3600 `
  -ZoneName ${DNS_ZONE_NAME} `
  -ResourceGroupName ${ARG_NAME} `
  -TargetResourceId $PublicIp.Id

# VNET

Get-AzVirtualNetwork `
  -Name ${VNET_NAME} `
  -ResourceGroupName ${ARG_NAME}


Name                   : myVnet
ResourceGroupName      : myResourceGroup004
Location               : westeurope
Id                     : /subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myResourceGroup004/providers/Microsoft.
                         Network/virtualNetworks/myVnet
Etag                   : W/"41c4d3e2-d0eb-4622-b9b8-c26356111f47"
ResourceGuid           : f150cd77-9fbb-4043-9ff9-7f2632e3c814
ProvisioningState      : Succeeded
Tags                   :
AddressSpace           : {
                           "AddressPrefixes": [
                             "10.0.0.0/16"
                           ]
                         }
DhcpOptions            : {}
Subnets                : [...]
VirtualNetworkPeerings : []
EnableDdosProtection   : false

$VNet = New-AzVirtualNetwork `
  -Name ${VNET_NAME} `
  -ResourceGroupName ${ARG_NAME} `
  -Location ${LOCATION} `
  -AddressPrefix 10.0.0.0/16 

# VNET Subnet

PS /home/robert> $VNet = Get-AzVirtualNetwork `
>>   -Name ${VNET_NAME} `
>>   -ResourceGroupName ${ARG_NAME}
PS /home/robert> $VNet.Subnets

Name                              : subnetACI-customer003
Id                                : /subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myResourceGroup004/providers
                                    /Microsoft.Network/virtualNetworks/myVnet/subnets/subnetACI-customer003
Etag                              : W/"41c4d3e2-d0eb-4622-b9b8-c26356111f47"
ProvisioningState                 : Succeeded
AddressPrefix                     : {10.0.2.0/24}
IpConfigurations                  : []
ResourceNavigationLinks           : []
ServiceAssociationLinks           : [
                                      {
                                        "Name": "acisal",
                                        "Etag": "W/\"41c4d3e2-d0eb-4622-b9b8-c26356111f47\"",
                                        "Id": "/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myResourceGroup00
                                    4/providers/Microsoft.Network/virtualNetworks/myVnet/subnets/subnetACI-customer003/serviceAssoc
                                    iationLinks/acisal",
                                        "LinkedResourceType": "Microsoft.ContainerInstance/containerGroups",
                                        "ProvisioningState": "Succeeded"
                                      }
                                    ]
NetworkSecurityGroup              : null
RouteTable                        : null
NatGateway                        : null
ServiceEndpoints                  : [
                                      {
                                        "ProvisioningState": "Succeeded",
                                        "Service": "Microsoft.Sql",
                                        "Locations": [
                                          "westeurope"
                                        ]
                                      }
                                    ]
ServiceEndpointPolicies           : []
PrivateEndpoints                  : []
PrivateEndpointNetworkPolicies    : Enabled
PrivateLinkServiceNetworkPolicies : Enabled


Add-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_APP_GW_NAME} `
  -VirtualNetwork $VNet `
  -AddressPrefix 10.0.0.0/24 | Set-AzVirtualNetwork




Name                              : subnetAAG
Id                                : /subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myResourceGroup004/providers
                                    /Microsoft.Network/virtualNetworks/myVnet/subnets/subnetAAG
Etag                              : W/"41c4d3e2-d0eb-4622-b9b8-c26356111f47"
ProvisioningState                 : Succeeded
AddressPrefix                     : {10.0.1.0/25}
IpConfigurations                  : []
ResourceNavigationLinks           : []
ServiceAssociationLinks           : []
NetworkSecurityGroup              : null
RouteTable                        : null
NatGateway                        : null
ServiceEndpoints                  : []
ServiceEndpointPolicies           : []
PrivateEndpoints                  : []
PrivateEndpointNetworkPolicies    : Enabled
PrivateLinkServiceNetworkPolicies : Enabled



Add-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_ACI_NAME} `
  -VirtualNetwork $VNet `
  -AddressPrefix 10.0.1.0/24 `
| Set-AzVirtualNetwork

# App GW

Get-AzApplicationGateway `
 -Name ${APP_GW_NAME} `
 -ResourceGroupName ${ARG_NAME}

Sku                                 : Microsoft.Azure.Commands.Network.Models.PSApplicationGatewaySku
SslPolicy                           :
GatewayIPConfigurations             : {appGatewayIpConfig}
AuthenticationCertificates          : {}
SslCertificates                     : {}
TrustedRootCertificates             : {}
TrustedClientCertificates           : {}
FrontendIPConfigurations            : {appGwPublicFrontendIp}
FrontendPorts                       : {port_80}
Probes                              : {}
BackendAddressPools                 : {myAppGwBackendPoolCustomer002}
BackendHttpSettingsCollection       : {myAppGwHttpSettings}
SslProfiles                         : {}
HttpListeners                       : {myAppGwListenerNameCustomer002}
UrlPathMaps                         : {}
RequestRoutingRules                 : {myAppGwRuleCustomer002}
RewriteRuleSets                     : {}
RedirectConfigurations              : {}
WebApplicationFirewallConfiguration :
FirewallPolicy                      :
AutoscaleConfiguration              :
CustomErrorConfigurations           : {}
PrivateLinkConfigurations           : {}
PrivateEndpointConnections          : {}
EnableHttp2                         : False
EnableFips                          :
ForceFirewallPolicyAssociation      :
Zones                               : {}
OperationalState                    : Running
ProvisioningState                   : Succeeded
Identity                            :

# APP GW IP CONFIG

$AppGw = Get-AzApplicationGateway `
-Name ${APP_GW_NAME} `
-ResourceGroupName ${ARG_NAME}

Get-AzApplicationGatewayIPConfiguration `
-Name ${APP_GW_IP_CONF_NAME} `
-ApplicationGateway $AppGw

PS /home/robert> $AppGw.GatewayIPConfigurations

Subnet            : Microsoft.Azure.Commands.Network.Models.PSResourceId
ProvisioningState : Succeeded
Type              : Microsoft.Network/applicationGateways/gatewayIPConfigurations
SubnetText        : {
                      "Id": "/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myResourceGroup004/providers/Micros
                    oft.Network/virtualNetworks/myVnet/subnets/subnetAAG"
                    }
Name              : appGatewayIpConfig
Etag              : W/"f882c583-aa47-48d2-bef5-7c5d8c3fe44c"
Id                : /subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myResourceGroup004/providers/Microsoft.Netwo
                    rk/applicationGateways/myAppGw/gatewayIPConfigurations/appGatewayIpConfig
   
$GatewayIPConfigurations = New-AzApplicationGatewayIPConfiguration `
  -Name ${APP_GW_IP_CONF_NAME} `
  -Subnet $SubnetAppGw

# APP GW SKU

Get-AzApplicationGatewaySku -ApplicationGateway $AppGw

Name        Tier        Capacity
----        ----        --------
Standard_v2 Standard_v2        1

$Sku = New-AzApplicationGatewaySku -Name ${APP_GW_SKU} -Tier Standard_v2 -Capacity 1



# APP GW 

Get-AzApplicationGatewayBackendHttpSettings -ApplicationGateway $AppGw

Port                           : 80
Protocol                       : Http
CookieBasedAffinity            : Disabled
RequestTimeout                 : 20
ConnectionDraining             :
Probe                          :
AuthenticationCertificates     : {}
TrustedRootCertificates        : {}
HostName                       :
PickHostNameFromBackendAddress : False
AffinityCookieName             : ApplicationGatewayAffinity
Path                           :
ProvisioningState              : Succeeded
Type                           : Microsoft.Network/applicationGateways/backendHttpSettingsCollection
ConnectionDrainingText         : null
ProbeText                      : null
AuthenticationCertificatesText : []
Name                           : myAppGwHttpSettings
Etag                           : W/"f882c583-aa47-48d2-bef5-7c5d8c3fe44c"
Id                             : /subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myResourceGroup004/providers/Mi
                                 crosoft.Network/applicationGateways/myAppGw/backendHttpSettingsCollection/myAppGwHttpSettings

$BackendSettings = New-AzApplicationGatewayBackendHttpSettings `
  -Name ${APP_GW_BACK_HTTP_SETS_NAME} `
  -Port ${APP_GW_BACK_POOL_PORT} `
  -Protocol ${APP_GW_BACK_POOL_PROTO} `
  -CookieBasedAffinity "Disabled" `
  -RequestTimeout 20

# APP GW Backend Pool

Get-AzApplicationGatewayBackendAddressPool -ApplicationGateway $AppGw

BackendAddresses            : {Microsoft.Azure.Commands.Network.Models.PSApplicationGatewayBackendAddress}
BackendIpConfigurations     : {}
ProvisioningState           : Succeeded
Type                        : Microsoft.Network/applicationGateways/backendAddressPools
BackendAddressesText        : [
                                {
                                  "IpAddress": "10.0.2.4"
                                }
                              ]
BackendIpConfigurationsText : []
Name                        : myAppGwBackendPoolCustomer002
Etag                        : W/"f882c583-aa47-48d2-bef5-7c5d8c3fe44c"
Id                          : /subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myResourceGroup004/providers/Micro
                              soft.Network/applicationGateways/myAppGw/backendAddressPools/myAppGwBackendPoolCustomer002

$CustomerBackendPool = New-AzApplicationGatewayBackendAddressPool `
  -Name ${APP_GW_BACK_POOL_NAME}

# App GW AzApplicationGatewayHttpListener

PS /home/robert> Get-AzApplicationGatewayHttpListener -ApplicationGateway $AppGw

FrontendIpConfiguration     : Microsoft.Azure.Commands.Network.Models.PSResourceId
FrontendPort                : Microsoft.Azure.Commands.Network.Models.PSResourceId
Protocol                    : Http
HostName                    : customer002.lubimyjedzenie.pl
HostNames                   : {}
SslCertificate              :
RequireServerNameIndication : False
ProvisioningState           : Succeeded
Type                        : Microsoft.Network/applicationGateways/httpListeners
CustomErrorConfigurations   : {}
FirewallPolicy              :
SslProfile                  :
FrontendIpConfigurationText : {
                                "Id": "/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myResourceGroup004/provid
                              ers/Microsoft.Network/applicationGateways/myAppGw/frontendIPConfigurations/appGwPublicFrontendIp"
                              }
FrontendPortText            : {
                                "Id": "/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myResourceGroup004/provid
                              ers/Microsoft.Network/applicationGateways/myAppGw/frontendPorts/port_80"
                              }
SslCertificateText          : null
SslProfileText              : null
FirewallPolicyText          : null
Name                        : myAppGwListenerNameCustomer002
Etag                        : W/"f882c583-aa47-48d2-bef5-7c5d8c3fe44c"
Id                          : /subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myResourceGroup004/providers/Micro
                              soft.Network/applicationGateways/myAppGw/httpListeners/myAppGwListenerNameCustomer002


$FrontEndPort = Get-AzApplicationGatewayFrontendPort -ApplicationGateway $AppGw
$FrontEndIpConfig = Get-AzApplicationGatewayFrontendIPConfig -ApplicationGateway $AppGw 

$CustomerListener = New-AzApplicationGatewayHttpListener `
  -Name ${APP_GW_HTTP_LISTE_NAME} `
  -Protocol ${APP_GW_BACK_POOL_PROTO} `
  -FrontendPort $FrontEndPort `
  -FrontendIpConfiguration $FrontEndIpConfig `
  -HostName ${APP_GW_HTTP_LISTE_HOST_NAME}


# APP GW Rule

Get-AzApplicationGatewayRequestRoutingRule -ApplicationGateway $AppGw

RuleType                  : Basic
Priority                  :
BackendAddressPool        : Microsoft.Azure.Commands.Network.Models.PSResourceId
BackendHttpSettings       : Microsoft.Azure.Commands.Network.Models.PSResourceId
HttpListener              : Microsoft.Azure.Commands.Network.Models.PSResourceId
UrlPathMap                :
RewriteRuleSet            :
RedirectConfiguration     :
ProvisioningState         : Succeeded
Type                      : Microsoft.Network/applicationGateways/requestRoutingRules
BackendAddressPoolText    : {
                              "Id": "/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myResourceGroup004/provider
                            s/Microsoft.Network/applicationGateways/myAppGw/backendAddressPools/myAppGwBackendPoolCustomer002"
                            }
BackendHttpSettingsText   : {
                              "Id": "/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myResourceGroup004/provider
                            s/Microsoft.Network/applicationGateways/myAppGw/backendHttpSettingsCollection/myAppGwHttpSettings"
                            }
HttpListenerText          : {
                              "Id": "/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myResourceGroup004/provider
                            s/Microsoft.Network/applicationGateways/myAppGw/httpListeners/myAppGwListenerNameCustomer002"
                            }
UrlPathMapText            : null
RewriteRuleSetText        : null
RedirectConfigurationText : null
Name                      : myAppGwRuleCustomer002
Etag                      : W/"f882c583-aa47-48d2-bef5-7c5d8c3fe44c"
Id                        : /subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myResourceGroup004/providers/Microso
                            ft.Network/applicationGateways/myAppGw/requestRoutingRules/myAppGwRuleCustomer002

$CustomerRule = New-AzApplicationGatewayRequestRoutingRule `
  -Name ${APP_GW_ROUTING_RULE_NAME} `
  -RuleType Basic `
  -BackendHttpSettings $BackendSettings `
  -HttpListener $CustomerListener `
  -BackendAddressPool $CustomerBackendPool

```
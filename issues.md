# ARM Templates vs Bicep Templates

## (NO) Support for remote Bicep Files

> Note
> 
> Currently, Azure PowerShell doesn't support deploying remote Bicep files.
> 
> Use Bicep CLI to compile the Bicep file to a JSON template, and then load the JSON file to the remote location.

# Public IP and AppGW

1. Public IP Basic Tier with Dynamic IP + App GW Standard (Small)
2. Public IP Standard Tier with Static IP + App Gw Standard_v2 (Small)

# Put App GW Subnet in Security Group

[Azure Application Gateway infrastructure configuration](https://docs.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure)

## Network security groups

[Azure Application Gateway infrastructure configuration](https://docs.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure#network-security-groups)

[Azure Application Gateway infrastructure configuration](https://docs.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure#allow-access-to-a-few-source-ips)

Network security groups (NSGs) are supported on Application Gateway. But there are some restrictions:

- You must allow incoming Internet traffic on TCP ports 65503-65534 for the Application Gateway v1 SKU, and TCP ports 65200-65535 for the v2 SKU with the destination subnet as Any and source as GatewayManager service tag. This port range is required for Azure infrastructure communication. These ports are protected (locked down) by Azure certificates. External entities, including the customers of those gateways, can't communicate on these endpoints.

- Outbound Internet connectivity can't be blocked. Default outbound rules in the NSG allow Internet connectivity. We recommend that you:

  - Don't remove the default outbound rules.
  - Don't create other outbound rules that deny any outbound connectivity.

- Traffic from the AzureLoadBalancer tag with the destination subnet as Any must be allowed.

### Allow access from specific port, ie. 80

Lets set it up to have some security and allow to connect to our Web App behing App Gateway via port 80. 

Our finall inbound rules should look like this:

![](2021-04-07-22-45-52.png)

Apply rules in this order of descending priority:

- Allow incoming traffic from a source IP or IP range with the destination as the entire Application Gateway subnet address range and destination port as your inbound access port, for example, port 80 for HTTP access.

![](2021-04-07-22-44-00.png)

> Verify that it works by changing port to 90. We should be not capable to connect to our web app anymore.

- You must allow incoming Internet traffic on TCP ports 65503-65534 for the Application Gateway v1 SKU, and TCP ports 65200-65535 for the v2 SKU with the destination subnet as Any and source as GatewayManager service tag. This port range is required for Azure infrastructure communication. These ports are protected (locked down) by Azure certificates. External entities, including the customers of those gateways, can't communicate on these endpoints.

![](2021-04-07-22-35-16.png)

- Traffic from the AzureLoadBalancer tag with the destination subnet as Any must be allowed. Allow incoming Azure Load Balancer probes (AzureLoadBalancer tag) and inbound virtual network traffic (VirtualNetwork tag) on the network security group.

![](2021-04-07-22-34-18.png)

![](2021-04-07-22-36-31.png)

- Allow outbound traffic to the Internet for all destinations. Outbound Internet connectivity can't be blocked. Default outbound rules in the NSG allow Internet connectivity. We recommend that you:

  - Don't remove the default outbound rules.
  - Don't create other outbound rules that deny any outbound connectivity.

# Use Security Groups to allow trafic from (ACI) Container Instance to MySql Server and deny to Internet

Our final outbound rules should look like

![](2021-04-07-22-57-23.png)

ACI can only accept traffic from your IP, it can only send traffic to Azure Storage, and the target storage account only accepts traffic from the service endpoint.

We have to associate ACI Subnet to this SecGroup

![](2021-04-07-22-06-13.png)

Allow traffic from VNet to 

![](2021-04-07-22-01-42.png)

![](2021-04-07-22-04-10.png)

# How to connect to MySQL Server via VNet from (ACI) Container Instance? Use VNET Service Endpoints - enabled per service (ie. Microsoft.Sql), per subnet (ie. myAciSubnet).

[Azure virtual network service endpoint policies](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoint-policies-overview#configuration)

[VNet service endpoints - Azure Database for MySQL](https://docs.microsoft.com/en-us/azure/mysql/concepts-data-access-and-security-vnet)

[Azure virtual network service endpoints](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview)

[Azure virtual network service endpoints](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview)

![](2021-04-07-20-58-59.png)

> Across all Subnets (FrontendSubnet, HDISubnet, BackendSubnet) in one VNET, when we have opened Security Enpoint in one Subnet (HDISubnet) pointing to MySQL Server, then Resources from other Subnets ie. Frontend (in same VNET!) can not access that MySQL Server.

![](2021-04-07-21-16-17.png)

> Virtual Network (VNet) service endpoint policies allow you to filter egress virtual network traffic to Azure Storage accounts over service endpoint, and allow data exfiltration to only specific Azure Storage accounts. Endpoint policies provide granular access control for virtual network traffic to Azure Storage when connecting over service endpoint.

**How to connect Container Group to MySQL Server without using firewall?** MySQL Server has to be at least General Purpose Sku, then in its Connection Security we create VNET Rule that will open VNET Service Endpoint in selected Subnet to which our ie. Container Instance Belongs.

**Can we have two different subnets - one for MySQL, another for Container Group?** No! We cant put MySQL in Subnet directly as with Container Group, but we can create Service Enpoint in given VNET Subnet to give access to MySQL Server from Resources in that Subnet. 

For this example purpose do create VNet, the Subnet (we can have bunch of other a Subnets), MySQL Server, Container Group in VNet the Subnet. Then in MySQL Server Connection security

![](2021-04-07-21-14-12.png)

We can create VNET Rule for our VNET where we select the Subnet. 

![](2021-04-07-21-20-55.png)

It will create Service Enpoint for service `Microsoft.Sql` in our Vnet the Subnet

![](2021-04-07-21-22-35.png)

Then this VNET Rule will allow to communicate inside the Subnet via underlaying networking to the MySQL Server. 

Finally our Backend Server, ie. in Container Instance can connect to MySQL Server, as they are in the same the Subnet. On the other hand, Container Instances from other a Subnets can not access that MySQL Server, as they are not in the Subnet.


## Terminology and description

### Virtual network: 

You can have virtual networks associated with your Azure subscription.

### Subnet: 

A virtual network contains subnets. Any Azure virtual machines (VMs) that you have are assigned to subnets. One subnet can contain multiple VMs or other compute nodes. Compute nodes that are outside of your virtual network cannot access your virtual network unless you configure your security to allow access.

### Virtual Network service endpoint: 

A Virtual Network service endpoint is a subnet whose property values include one or more formal Azure service type names. In this article we are interested in the type name of Microsoft.Sql, which refers to the Azure service named SQL Database. This service tag also applies to the Azure Database for MySQL and PostgreSQL services. It is important to note when applying the Microsoft.Sql service tag to a VNet service endpoint it will configure service endpoint traffic for all Azure SQL Database, Azure Database for MySQL and Azure Database for PostgreSQL servers on the subnet.

### Virtual network rule: 

A virtual network rule for your Azure Database for MySQL server is a subnet that is listed in the access control list (ACL) of your Azure Database for MySQL server. To be in the ACL for your Azure Database for MySQL server, the subnet must contain the Microsoft.Sql type name.

A virtual network rule tells your Azure Database for MySQL server to accept communications from every node that is on the subnet.


# New-AzMySqlVirtualNetworkRule_CreateExpanded: This feature is not available for the selected edition 'Basic'.

```ps1
$MySqlSrv=(Get-AzMySqlServer -Name ${MY_SQL_SRV_NAME}  -ResourceGroupName ${RES_GR_NAME})
$ServiceName = $MySqlSrv.Type

$VNet = Get-AzVirtualNetwork `
  -Name ${VNET_NAME_CONT_GR} `
  -ResourceGroupName ${RES_GR_NAME}

Add-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_MYSQL_SRV} `
  -VirtualNetwork $VNet `
  -AddressPrefix 10.0.2.0/24 `
  -ServiceEndpoint Microsoft.Sql `
| Set-AzVirtualNetwork

$VNet = Get-AzVirtualNetwork `
  -Name ${VNET_NAME_CONT_GR} `
  -ResourceGroupName ${RES_GR_NAME}

$MySqlSubnet = Get-AzVirtualNetworkSubnetConfig `
   -Name ${VNET_SUB_MYSQL_SRV} `
   -VirtualNetwork $VNet 

New-AzMySqlVirtualNetworkRule `
  -Name ${MY_SQL_SRV_VNET_RULE_NAME} `
  -ServerName ${MY_SQL_SRV_NAME} `
  -ResourceGroupName ${RES_GR_NAME} `
  -SubnetId $MySqlSubnet.Id
```


# Service types for subnet delegations

```sh

$MySqlSrv=(Get-AzMySqlServer -Name ${MY_SQL_SRV_NAME}  -ResourceGroupName ${RES_GR_NAME})
$ServiceName = $MySqlSrv.Type

$VNet = Get-AzVirtualNetwork `
  -Name ${VNET_NAME_CONT_GR} `
  -ResourceGroupName ${RES_GR_NAME}

# This subnet will be delegated only to use with MySQL Flexible Server service
$Delegation = New-AzDelegation `
  -Name ${VNET_SUB_MYSQL_SRV_DELEGATION} `
  -ServiceName $ServiceName

# FIXME does not work with MySQL but does with MySQL Flexible
Add-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_MYSQL_SRV} `
  -VirtualNetwork $VNet `
  -AddressPrefix 10.0.2.0/24 `
  -Delegation $delegation `
| Set-AzVirtualNetwork

# List of supported ServiceName's

# Microsoft.Network/fpgaNetworkInterfaces,
# Microsoft.Web/serverFarms,
# Microsoft.ContainerInstance/containerGroups,
# Microsoft.Netapp/volumes,
# Microsoft.HardwareSecurityModules/dedicatedHSMs,
# Microsoft.ServiceFabricMesh/networks,
# Microsoft.Logic/integrationServiceEnvironments,
# Microsoft.Batch/batchAccounts,
# Microsoft.Sql/managedInstances,
# Microsoft.Web/hostingEnvironments,
# Microsoft.BareMetal/CrayServers,
# Microsoft.BareMetal/MonitoringServers,
# Microsoft.Databricks/workspaces,
# Microsoft.BareMetal/AzureHostedService,
# Microsoft.BareMetal/AzureVMware,
# Microsoft.BareMetal/AzureHPC,
# Microsoft.BareMetal/AzurePaymentHSM,
# Microsoft.StreamAnalytics/streamingJobs,
# Microsoft.DBforPostgreSQL/serversv2,
# Microsoft.AzureCosmosDB/clusters,
# Microsoft.MachineLearningServices/workspaces,
# Microsoft.DBforPostgreSQL/singleServers,
# Microsoft.DBforPostgreSQL/flexibleServers,
# Microsoft.DBforMySQL/serversv2, <--- WT is that?
# Microsoft.DBforMySQL/flexibleServers,
# Microsoft.ApiManagement/service,
# Microsoft.Synapse/workspaces,
# Microsoft.PowerPlatform/vnetaccesslinks,
# Microsoft.Network/dnsResolvers,
# Microsoft.Kusto/clusters,
# Microsoft.DelegatedNetwork/controller,
# Microsoft.ContainerService/managedClusters,
# Microsoft.PowerPlatform/enterprisePolicies,
# Microsoft.Network/virtualNetworkGateways.
```

# Service endpoints for subnet config

```ps1

Add-AzVirtualNetworkSubnetConfig `
  -Name ${VNET_SUB_MYSQL_SRV} `
  -VirtualNetwork $VNet `
  -AddressPrefix 10.0.2.0/24 `
  -ServiceEndpoint Microsoft.Sql `
| Set-AzVirtualNetwork


PS /home/robert> az network service-endpoint list --location  ${LOCATION}
[
  {
    "id": "/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/providers/Microsoft.Network/virtualNetworkEndpointServices/Microsoft.Storage",
    "name": "Microsoft.Storage",
    "type": "Microsoft.Network/virtualNetworkEndpointServices"
  },
  {
    "id": "/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/providers/Microsoft.Network/virtualNetworkEndpointServices/Microsoft.Sql",
    "name": "Microsoft.Sql",
    "type": "Microsoft.Network/virtualNetworkEndpointServices"
  },
  {
    "id": "/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/providers/Microsoft.Network/virtualNetworkEndpointServices/Microsoft.AzureActiveDirectory",
    "name": "Microsoft.AzureActiveDirectory",
    "type": "Microsoft.Network/virtualNetworkEndpointServices"
  },
  {
    "id": "/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/providers/Microsoft.Network/virtualNetworkEndpointServices/Microsoft.AzureCosmosDB",
    "name": "Microsoft.AzureCosmosDB",
    "type": "Microsoft.Network/virtualNetworkEndpointServices"
  },
  {
    "id": "/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/providers/Microsoft.Network/virtualNetworkEndpointServices/Microsoft.Web",
    "name": "Microsoft.Web",
    "type": "Microsoft.Network/virtualNetworkEndpointServices"
  },
  {
    "id": "/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/providers/Microsoft.Network/virtualNetworkEndpointServices/Microsoft.KeyVault",
    "name": "Microsoft.KeyVault",
    "type": "Microsoft.Network/virtualNetworkEndpointServices"
  },
  {
    "id": "/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/providers/Microsoft.Network/virtualNetworkEndpointServices/Microsoft.EventHub",
    "name": "Microsoft.EventHub",
    "type": "Microsoft.Network/virtualNetworkEndpointServices"
  },
  {
    "id": "/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/providers/Microsoft.Network/virtualNetworkEndpointServices/Microsoft.ServiceBus",
    "name": "Microsoft.ServiceBus",
    "type": "Microsoft.Network/virtualNetworkEndpointServices"
  },
  {
    "id": "/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/providers/Microsoft.Network/virtualNetworkEndpointServices/Microsoft.ContainerRegistry",
    "name": "Microsoft.ContainerRegistry",
    "type": "Microsoft.Network/virtualNetworkEndpointServices"
  },
  {
    "id": "/subscriptions/53cda94b-af20-45ab-82c0-04e260445517/providers/Microsoft.Network/virtualNetworkEndpointServices/Microsoft.CognitiveServices",
    "name": "Microsoft.CognitiveServices",
    "type": "Microsoft.Network/virtualNetworkEndpointServices"
  }
]
PS /home/robert>
```

# Keyvault - The user, group or application xxx does not have secrets set permission on key vault 

```ps1
 /home/robert> az keyvault secret set `
>>   --vault-name $AKV_NAME `
>>   --name $AAD_ACR_PULL_SECRET_NAME `
>>   --value $AAD_ACR_PULL_SECRET
The user, group or application 'appid=b677c290-cf4b-4a8e-a60e-91ba650a4abe;oid=927b4ca8-5d40-4a4d-b0f0-d62576866ede;numgroups=1;iss=https://sts.windows.net/4e0bfea1-1425-4dbd-9173-7f9db28c3ded/' does not have secrets set permission on key vault 'myKeyVault911009;location=eastus'. For help resolving this issue, please see https://go.microsoft.com/fwlink/?linkid=2125287
```

Solutiuon: set access policy

![](2021-04-06-23-49-11.png)

# Set '*' A record in DNS Zone depending on Public IP type

```ps1

# AllocationMethod 'Dynamic', will allocate public IP only after associating resource.
$PublicIp = New-AzPublicIpAddress -ResourceGroupName ${RES_GR_NAME} -Name ${PUB_IP_NAME_APP_GW_NAME} -Location ${LOCATION} -AllocationMethod ${PUB_IP_ALLOCATION_METHOD} 

# use with dynamic IP -> associate to resource
az network dns record-set a create `
--name '*' `
--zone-name ${DNS_ZONE} `
--resource-group ${RES_GR_NAME} `
--target-resource "/subscriptions/${AZ_SUBS_ID}/resourceGroups/${RES_GR_NAME}/providers/Microsoft.Network/publicIPAddresses/${PUB_IP_NAME_APP_GW_NAME}"

# use with static IP
az network dns record-set a add-record `
     --resource-group ${RES_GR_NAME} `
     --zone-name ${DNS_ZONE} `
     --record-set-name '*' `
     --ipv4-address $PublicIp.IpAddress

```

# The 'nsdname' of a record set with type 'NS' and name '@' cannot be changed 

```ps1
PS /home/robert> $Zone = Get-AzDnsZone -Name ${DNS_ZONE} -ResourceGroupName ${RES_GR_NAME}
PS /home/robert>
PS /home/robert> $RecordSet = Get-AzDnsRecordSet -Name "@" -RecordType NS -Zone $Zone
PS /home/robert> $RecordSet

Id                : /subscriptions/53cda94b-af20-45ab-82c0-04e260445517/resourceGroups/myresourcegroup001/providers/Microsoft.Network/dnszones/lubiewarzywka.pl/NS/@
Name              : @
ZoneName          : lubiewarzywka.pl
ResourceGroupName : myresourcegroup001
Ttl               : 172800
Etag              : ecf1f31d-24fe-4227-80ca-4d2401e519ab
RecordType        : NS
TargetResourceId  :
Records           : {ns1-03.azure-dns.com., ns2-03.azure-dns.net., ns3-03.azure-dns.org., ns4-03.azure-dns.info.}
Metadata          :
ProvisioningState : Succeeded


PS /home/robert> $RecordSet.Records[0]

Nsdname
-------
ns1-03.azure-dns.com.

PS /home/robert> $RecordSet.Records[0].Nsdname = "ns1-01.azure-dns.com."
PS /home/robert> $RecordSet.Records[1].Nsdname = "ns2-01.azure-dns.net."
PS /home/robert> $RecordSet.Records[2].Nsdname = "ns3-01.azure-dns.org."
PS /home/robert> $RecordSet.Records[3].Nsdname = "ns4-01.azure-dns.info."
PS /home/robert> $RecordSet.Records

Nsdname
-------
ns1-01.azure-dns.com.
ns2-01.azure-dns.net.
ns3-01.azure-dns.org.
ns4-01.azure-dns.info.

PS /home/robert> Set-AzDnsRecordSet -RecordSet $RecordSet
Set-AzDnsRecordSet: The 'nsdname' of a record set with type 'NS' and name '@' cannot be changed
```
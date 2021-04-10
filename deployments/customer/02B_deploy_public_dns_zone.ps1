Set-StrictMode -Version Latest

. .env.ps1

echo "
#################################################################################
#### Create DNS Zone $DNS_ZONE_NAME and child zone app.$DNS_ZONE_NAME
#################################################################################"
$ErrorActionPreferencePrev = $ErrorActionPreference 
$ErrorActionPreference = "Continue"

# Create Dns Zone
$DnsZone = New-AzDnsZone `
  -Name ${DNS_ZONE_NAME} `
  -ResourceGroupName ${ARG_NAME} `
  -ZoneType Public 

New-AzDnsZone `
  -Name "app.${DNS_ZONE_NAME}" `
  -ResourceGroupName ${ARG_NAME} `
  -ZoneType Public `
  -ParentZoneName ${DNS_ZONE_NAME}

$DnsZone = (Get-AzDnsZone `
  -Name ${DNS_ZONE_NAME} `
  -ResourceGroupName ${ARG_NAME})

echo "[IMPORTANT] Update in Your domain provider ie. godaddy.com, the domain DNS settings with NS (skip dots at the suffix): ", $DnsZone.NameServers

$PublicIp = Get-AzPublicIpAddress `
  -ResourceGroupName ${ARG_NAME} `
  -Name ${PUB_IP_NAME} 

# Create type A name * record set targeting Public IP

New-AzDnsRecordSet `
  -Name '@' `
  -RecordType A `
  -Ttl 300 `
  -ZoneName ${DNS_ZONE_NAME} `
  -ResourceGroupName ${ARG_NAME} `
  -TargetResourceId $PublicIp.Id

New-AzDnsRecordSet `
  -Name '@' `
  -RecordType A `
  -Ttl 300 `
  -ZoneName "app.${DNS_ZONE_NAME}" `
  -ResourceGroupName ${ARG_NAME} `
  -TargetResourceId $PublicIp.Id

New-AzDnsRecordSet `
  -Name '*' `
  -RecordType A `
  -Ttl 300 `
  -ZoneName ${DNS_ZONE_NAME} `
  -ResourceGroupName ${ARG_NAME} `
  -TargetResourceId $PublicIp.Id

New-AzDnsRecordSet `
  -Name '*' `
  -RecordType A `
  -Ttl 300 `
  -ZoneName "app.${DNS_ZONE_NAME}" `
  -ResourceGroupName ${ARG_NAME} `
  -TargetResourceId $PublicIp.Id
# TODO handle update in better way
# $RecordSet = Get-AzDnsRecordSet `
#   -Name '*' `
#   -RecordType A `
#   -ZoneName ${DNS_ZONE_NAME} `
#   -ResourceGroupName ${ARG_NAME}

# $RecordSet.TargetResourceId = $PublicIp.Id
# Set-AzDnsRecordSet -RecordSet $RecordSet
$ErrorActionPreference =  $ErrorActionPreferencePrev

Get-AzDnsZone `
  -Name ${DNS_ZONE_NAME} `
  -ResourceGroupName ${ARG_NAME} 


Get-AzDnsZone `
  -Name "app.${DNS_ZONE_NAME}" `
  -ResourceGroupName ${ARG_NAME} 
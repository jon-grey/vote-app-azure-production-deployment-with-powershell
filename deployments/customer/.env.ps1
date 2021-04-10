Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#### TODO secrets for ACI, use https://olegkarasik.wordpress.com/2020/04/10/using-secrets-in-azure-container-instances/

#################################################################################
#### Env Variables
#################################################################################
$SUBSCRIPTION_ID="53cda94b-af20-45ab-82c0-04e260445517"

# ===============================================================================
# Multi tenant resources
# ===============================================================================
# TODO naming should match pattern '^[-\w\._\(\)]+$'

$UNIQUE_ID="292233"

$LOCATION="eastus"
$ARG_NAME="myResourceGroup-${UNIQUE_ID}" 
$AKV_NAME="myKeyVault-${UNIQUE_ID}"
$ACR_NAME="mycontainerregistry${UNIQUE_ID}"
$AMI_NAME="myManagedIdentity-${UNIQUE_ID}"
# computing: container registry
$ACR_ENC_KEY_NAME="myKeyForEncryptionOfContainerRegistry-$ACR_NAME"
# storage: mysql srv flexible
$MY_SQL_SRV_NAME="my-my-sql-srv-${UNIQUE_ID}"
$MY_SQL_SRV_VNET_RULE_NAME="myRuleAllowFromAciSubnetToMySql"
# networking: dns zone
$DNS_ZONE_NAME="lubiewarzywka.pl"

# auto $PUB_IP_ALLOCATION_METHOD="Static"
# auto $PUB_IP_SKU="Basic"
$PUB_IP_TIER="Regional"
# networking: vnet
$VNET_NAME="myVNet-$UNIQUE_ID"
$VNET_SUB_APP_GW_NAME="subnetAAG"
# networking: app gw
$APP_GW_NAME="myAppGw-$UNIQUE_ID"
# Smallest, cheapest App GW
# $APP_GW_SKU_NAME="Standard_Small"
# $APP_GW_SKU_TIER="Standard"
# Cheapest for multitenant
$APP_GW_SKU_NAME="Standard_v2"
$APP_GW_SKU_TIER="Standard_v2"

$APP_GW_SKU_CAP=1
$APP_GW_NET_SEC_GR_NAME="myNetSecGroup_$APP_GW_NAME"
# networking: app-gw:ip-config for vnet:subnet:app-gw
$APP_GW_IP_CONF_NAME="${APP_GW_NAME}IpConfig${VNET_SUB_APP_GW_NAME}" 

# networking: public ip
$PUB_IP_NAME="myPublicIp_${APP_GW_NAME}"

# ===============================================================================
# Common customer resources
# ===============================================================================

$ACI_IMAGE="${ACR_NAME}.azurecr.io/azure-vote-flask-mysql:v5"
$ACI_DUMMY_NAME="mycontainerinstance-dummy"
$ACI_DUMMY_IMAGE="mcr.microsoft.com/azuredocs/aks-helloworld:v1"

# computing: container group
$ACI_PORT=80
$ACI_PROTO="Http"

# ===============================================================================
# Customer resources
# ===============================================================================
$CUSTOMER_ID="223456"

# storage: mysql srv
$MY_SQL_SRV_NAME="my-my-sql-srv-customer-${CUSTOMER_ID}"
$ACI_NAME="mycontainerinstance-customer-${CUSTOMER_ID}"


# networking: sec group: aci
$ACI_NET_SEC_GR_NAME="myNetSecGroupACI-customer-${CUSTOMER_ID}"
# networking: vnet: subnet: aci
$VNET_SUB_ACI_NAME="subnetACI-customer-${CUSTOMER_ID}"
# networking: app gw: frontend
$APP_GW_FRONT_PORT=${ACI_PORT}
$APP_GW_FRONT_NAME="appGwFrontEndPort${ACI_PORT}"
# networking: app gw: backend
$APP_GW_BACK_HTTP_SETS_BASIC_NAME="appGwBackendSettings${ACI_PROTO}${ACI_PORT}"
$APP_GW_BACK_HTTP_SETS_CUSTOMER_NAME="${APP_GW_BACK_HTTP_SETS_BASIC_NAME}Customer${CUSTOMER_ID}"
# networking: app gw: backend pool
$APP_GW_BACK_POOL_PROTO=${ACI_PROTO}
$APP_GW_BACK_POOL_PORT=${ACI_PORT}
$APP_GW_BACK_POOL_BASIC_NAME="appGwBackendPool${ACI_PROTO}${ACI_PORT}"
$APP_GW_BACK_POOL_CUSTOMER_NAME="${APP_GW_BACK_POOL_BASIC_NAME}Customer${CUSTOMER_ID}"
# networking: app gw: http listener
$APP_GW_HTTP_LISTE_HOST_NAME="${CUSTOMER_ID}.app.${DNS_ZONE_NAME}".ToLower()
$APP_GW_HTTP_LISTE_BASIC_NAME="appGwHttpListener${ACI_PROTO}${ACI_PORT}"
$APP_GW_HTTP_LISTE_CUSTOMER_NAME="${APP_GW_HTTP_LISTE_BASIC_NAME}Customer${CUSTOMER_ID}"
# networking: app gw: routing rule
$APP_GW_ROUTING_RULE_BASIC_NAME="appGwRoutingRule"
$APP_GW_ROUTING_RULE_CUSTOMER_NAME="${APP_GW_ROUTING_RULE_BASIC_NAME}Customer${CUSTOMER_ID}"

# ===============================================================================
# MySQL Settings
# ===============================================================================
$MYSQL_ROOT_PASSWORD="Password12"
$MYSQL_ROOT_LOGIN="mysqladmin"
$MYSQL_ROOT_USERNAME="${MYSQL_ROOT_LOGIN}@${MY_SQL_SRV_NAME}"
$MYSQL_DATABASE_PASSWORD="Password12"
$MYSQL_DATABASE_USER="dbuser@${MY_SQL_SRV_NAME}"
$MYSQL_DATABASE_HOST="${MY_SQL_SRV_NAME}.mysql.database.azure.com"
$MYSQL_DATABASE_PORT="3306"
$MYSQL_DATABASE_DB="azurevote"
$TITLE="${ARG_NAME}_${ACI_NAME}_${VNET_NAME}_${VNET_SUB_ACI_NAME}"

# ===============================================================================
# Helper Functions
# ===============================================================================

function new-ipaddress {
    param (
        [string]$ip,
     
        [ValidateRange(0,255)]
        [int]$newoctet
    )
     $ip = ($ip -split '/')[0]
     $octets = $ip -split "\."
     $octets[3] = $newoctet.ToString()
     
     $newaddress = $octets -join "."
     $newaddress
}
Function pause ($message)
{
    Write-Host "$message" -ForegroundColor Yellow
    $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
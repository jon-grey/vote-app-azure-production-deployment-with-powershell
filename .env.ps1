Set-StrictMode -Version Latest

#### TODO secrets for ACI, use https://olegkarasik.wordpress.com/2020/04/10/using-secrets-in-azure-container-instances/

#################################################################################
#### Env Variables
#################################################################################
$SUBSCRIPTION_ID="53cda94b-af20-45ab-82c0-04e260445517"

# ===============================================================================
# Multi tenant resources
# ===============================================================================
# TODO naming should match pattern '^[-\w\._\(\)]+$'

$LOCATION="germanywestcentral"
$ARG_NAME="myResourceGroup002" 
$AKV_NAME="myKeyVault134234"
$ACR_NAME="azurecoreg"
# storage: mysql srv flexible
$MY_SQL_SRV_NAME="my-my-sql-srv"
$MY_SQL_SRV_FLEX_NAME="my-my-sql-srv-flex"
$MY_SQL_SRV_VNET_RULE_NAME="myRuleAllowFromAciSubnetToMySql"
# networking: dns zone
$DNS_ZONE_NAME="lubiewarzywka.pl"
# networking: public ip
$PUB_IP_NAME="myAGPublicIPAddress"
$PUB_IP_ALLOCATION_METHOD="Dynamic"
# networking: vnet
$VNET_NAME="myVNet"
$VNET_SUB_APP_GW_NAME="myAGSubnet"
# networking: app gw
$APP_GW_NAME="myAppGateway"
$APP_GW_SKU="Standard_Small"
$APP_GW_NET_SEC_GR_NAME="myNetSecGroupAppGw"
# networking: app gw: backend
$APP_GW_BACK_HTTP_SETS_NAME="${APP_GW_NAME}_BackendHttpSettings"
# networking: app-gw:ip-config for vnet:subnet:app-gw
$APP_GW_IP_CONF_NAME="${APP_GW_NAME}_IpConfig_${VNET_SUB_APP_GW_NAME}" 

# ===============================================================================
# Customer resources
# ===============================================================================
$CUSTOMER_ID="customer-001"
# computing: container group
$ACI_PORT=80
# storage: mysql srv
$MY_SQL_SRV_NAME="my-my-sql-srv-${CUSTOMER_ID}"
#$ACI_IMAGE="mcr.microsoft.com/azuredocs/aks-helloworld:v1"
$ACI_IMAGE="${ACR_NAME}.azurecr.io/azure-vote-flask-mysql:v5"
$ACI_NAME="appcontainer-${CUSTOMER_ID}"
# networking: sec group: aci
$ACI_NET_SEC_GR_NAME="myNetSecGroupACI_${CUSTOMER_ID}"
# networking: vnet: subnet: aci
$VNET_SUB_ACI_NAME="myACISubnet_${CUSTOMER_ID}"
# networking: app gw: frontend
$APP_GW_FRONT_PORT=${ACI_PORT}
$APP_GW_FRONT_NAME="${APP_GW_NAME}_FrontEndPort_${APP_GW_FRONT_PORT}"
$APP_GW_FRONT_CONF_NAME="${APP_GW_NAME}_FrontEndIpConfig_${PUB_IP_NAME}" 
# networking: app gw: backend pool
$APP_GW_BACK_POOL_PROTO="Http"
$APP_GW_BACK_POOL_PORT=${ACI_PORT}
$APP_GW_BACK_POOL_NAME="${APP_GW_NAME}_BackendPool_${APP_GW_BACK_POOL_PROTO}_${APP_GW_BACK_POOL_PORT}_$CUSTOMER_ID"
# networking: app gw: http listener
$APP_GW_HTTP_LISTE_HOST_NAME="${CUSTOMER_ID}.${DNS_ZONE_NAME}".ToLower()
$APP_GW_HTTP_LISTE_NAME="${APP_GW_NAME}_HttpListener_${APP_GW_BACK_POOL_PROTO}_${APP_GW_FRONT_PORT}_${CUSTOMER_ID}"
# networking: app gw: routing rule
$APP_GW_ROUTING_RULE_NAME="${APP_GW_NAME}_RoutingRule_$CUSTOMER_ID"

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

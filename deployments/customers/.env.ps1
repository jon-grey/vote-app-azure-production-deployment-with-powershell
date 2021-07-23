Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. ./powershell-scripts/scripts.ps1
Set-PsEnv ./.env.secrets

#### TODO secrets for ACI, use https://olegkarasik.wordpress.com/2020/04/10/using-secrets-in-azure-container-instances/

#################################################################################
#### Load Env Variables
#################################################################################
$AZ_SUBS_ID="53cda94b-af20-45ab-82c0-04e260445517"

# ===============================================================================
# Load internal Env Variables
# ===============================================================================
# TODO naming should match pattern '^[-\w\._\(\)]+$'
$UNIQUE_ID="Internal"
$LOCATION="eastus"
# resource group
$ARG_INTERNAL_NAME="myResourceGroup-${UNIQUE_ID}" 
# storage: key vault
$AKV_NAME="myKeyVault-${UNIQUE_ID}"
# users: managed identity
$AMI_NAME="myManagedIdentity-${UNIQUE_ID}"
# computing: container registry
$ACR_NAME="myContaineRregistry${UNIQUE_ID}"
$ACR_NAME_LOW=$ACR_NAME.ToLower()
$ACR_ENC_KEY_NAME="myKeyForEncryptionOfContainerRegistry-$ACR_NAME"
# computing: aci: images from acr
$ACI_IMAGE="${ACR_NAME_LOW}.azurecr.io/azure-vote-flask-mysql:v5"
$ACI_DUMMY_NAME="mycontainerinstance-dummy"
$ACI_DUMMY_IMAGE="mcr.microsoft.com/azuredocs/aks-helloworld:v1"

# ===============================================================================
# Load common customer Env Variables
# ===============================================================================
# TODO naming should match pattern '^[-\w\._\(\)]+$'
$UNIQUE_ID="492233"
$ARG_NAME="myResourceGroup-${UNIQUE_ID}" 
$ANP_NAME="myNetworkProfile-${UNIQUE_ID}"
# computing: container registry
$ACR_ENC_KEY_NAME="myKeyForEncryptionOfContainerRegistry-$ACR_NAME"
# storage: mysql srv 
$MY_SQL_SRV_VNET_RULE_NAME="myRuleAllowFromAciSubnetToMySql"
# networking: dns zone
$DNS_ZONE_NAME="lubimyjedzenie.pl"
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
# computing: container group
$ACI_PORT=80
$ACI_PROTO="Http"
# networking: vnet: subnet: aci
$VNET_SUB_ACI_DUMMY_NAME="subnetACI-customer-dummy"
# networking: app gw: frontend
$APP_GW_FRONT_PORT=${ACI_PORT}
# networking: app gw: frontend
$APP_GW_FRONT_PORT=${ACI_PORT}
$APP_GW_FRONT_NAME="appGwFrontEndPort${ACI_PORT}"
# networking: app gw: backend
$APP_GW_BACK_HTTP_SETS_BASIC_NAME="appGwBackendSettings${ACI_PROTO}${ACI_PORT}"
$APP_GW_BACK_HTTP_SETS_CUSTOMERS_NAME="${APP_GW_BACK_HTTP_SETS_BASIC_NAME}Customers"
# networking: app gw: backend pool
$APP_GW_BACK_POOL_PROTO=${ACI_PROTO}
$APP_GW_BACK_POOL_PORT=${ACI_PORT}
$APP_GW_BACK_POOL_BASIC_NAME="appGwBackendPool${ACI_PROTO}${ACI_PORT}"
# networking: app gw: http listener
$APP_GW_HTTP_LISTE_BASIC_NAME="appGwHttpListener${ACI_PROTO}${ACI_PORT}"
# networking: app gw: routing rule
$APP_GW_ROUTING_RULE_BASIC_NAME="appGwRoutingRule"

# networking: sec group: aci
$ACI_NET_SEC_GR_NAME="myNetSecGroup_ACI-$UNIQUE_ID"

# ===============================================================================
# Load customer Env Variables
# ===============================================================================

$CUSTOMERS_MAP = @{}
$CUSTOMERS_IDX = (1..10).ForEach({ '{0:D7}' -f ([int]21050000 + [int]$_)  })

$CUSTOMERS_IDX.forEach{
    $CustomerId = $_

    # computing: aci
    $ACI_NAME="mycontainerinstance-customer-${CustomerId}"
    # networking: vnet: subnet: aci
    $VNET_SUB_ACI_NAME="subnetACI-customer-${CustomerId}"
    # networking: app gw: frontend
    $APP_GW_FRONT_NAME="appGwFrontEndPort${ACI_PORT}"
    # networking: app gw: backend
    $APP_GW_BACK_HTTP_SETS_CUSTOMER_NAME="${APP_GW_BACK_HTTP_SETS_BASIC_NAME}Customer${CustomerId}"
    # networking: app gw: backend pool
    $APP_GW_BACK_POOL_CUSTOMER_NAME="${APP_GW_BACK_POOL_BASIC_NAME}Customer${CustomerId}"
    # networking: app gw: http listener
    $APP_GW_HTTP_LISTE_HOST_NAME="${CustomerId}.app.${DNS_ZONE_NAME}".ToLower()
    $APP_GW_HTTP_LISTE_CUSTOMER_NAME="${APP_GW_HTTP_LISTE_BASIC_NAME}Customer${CustomerId}"
    # networking: app gw: routing rule
    $APP_GW_ROUTING_RULE_CUSTOMER_NAME="${APP_GW_ROUTING_RULE_BASIC_NAME}Customer${CustomerId}"
    # computing: aci: title
    $ACI_TITLE="${ARG_NAME}_${ACI_NAME}_${VNET_NAME}_${VNET_SUB_ACI_NAME}"
    # storage: mysql server
    $MY_SQL_SRV_NAME="my-my-sql-srv-customer-${CustomerId}"
    # storage: mysql server: settings
    $MYSQL_ROOT_PASSWORD="Password12"
    $MYSQL_ROOT_LOGIN="mysqladmin"
    $MYSQL_DATABASE_PASSWORD="Password12"
    $MYSQL_DATABASE_PORT="3306"
    $MYSQL_DATABASE_DB="azurevote"
    $MYSQL_DATABASE_USER="dbuser@${MY_SQL_SRV_NAME}"
    $MYSQL_DATABASE_HOST="${MY_SQL_SRV_NAME}.mysql.database.azure.com"
    $MYSQL_ROOT_USERNAME="${MYSQL_ROOT_LOGIN}@${MY_SQL_SRV_NAME}"

    $CUSTOMERS_MAP[$CustomerId] = @{
        CUSTOMER_ID = $CustomerId;
        ACI_NAME =$ACI_NAME;
        VNET_SUB_ACI_NAME=$VNET_SUB_ACI_NAME;
        APP_GW_FRONT_NAME=$APP_GW_FRONT_NAME;
        APP_GW_BACK_HTTP_SETS_CUSTOMER_NAME=$APP_GW_BACK_HTTP_SETS_CUSTOMER_NAME;
        APP_GW_BACK_POOL_CUSTOMER_NAME=$APP_GW_BACK_POOL_CUSTOMER_NAME;
        APP_GW_HTTP_LISTE_HOST_NAME=$APP_GW_HTTP_LISTE_HOST_NAME;
        APP_GW_HTTP_LISTE_CUSTOMER_NAME=$APP_GW_HTTP_LISTE_CUSTOMER_NAME;
        APP_GW_ROUTING_RULE_CUSTOMER_NAME=$APP_GW_ROUTING_RULE_CUSTOMER_NAME;
        ACI_TITLE=$ACI_TITLE;
        MY_SQL_SRV_NAME=$MY_SQL_SRV_NAME;
        MYSQL_DATABASE_HOST =$MYSQL_DATABASE_HOST;
        MYSQL_DATABASE_USER=$MYSQL_DATABASE_USER;
        MYSQL_ROOT_USERNAME=$MYSQL_ROOT_USERNAME;
        MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD;
        MYSQL_ROOT_LOGIN=$MYSQL_ROOT_LOGIN;
        MYSQL_DATABASE_PASSWORD=$MYSQL_DATABASE_PASSWORD;
        MYSQL_DATABASE_PORT=$MYSQL_DATABASE_PORT;
        MYSQL_DATABASE_DB=$MYSQL_DATABASE_DB;
    }
}




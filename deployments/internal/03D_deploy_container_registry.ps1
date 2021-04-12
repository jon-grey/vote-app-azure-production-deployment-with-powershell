Set-StrictMode -Version Latest

. ./.env.ps1

echo '
#################################################################################
#### Create Container Registry
#################################################################################

#                         BASIC	            STANDARD	        PREMIUM
# Price per day	          $0.167	          $0.667	          $1.667
# Included storage (GB)	  10	              100	              500
#                                                             * Premium offers 
#                                                             * enhanced throughput 
#                                                             * for docker pulls 
#                                                             * across multiple, 
#                                                             * concurrent nodes
# Total web hooks	        2	                10	              500
# Geo Replication	        Not Supported	    Not Supported	    Supported
#                                                             * $1.667 per 
#                                                             * replicated region

# https://azure.microsoft.com/en-us/pricing/details/container-registry/

# TODO only premium support encryption, do we need it?
# TODO --identity and --key-encryption-key must be both supplied
# TODO Premium is paid $1.677 per day. Maybe can spend few bucks?
# * FIXME we can not use AMI to cross identity ACR and ACI so use premium
# * only if other benefits usefull
# PS1 does not supoort encr key
'

echo '
# ===============================================================================
# Get key ID
# ==============================================================================='

$ACR_ENC_KEY=Get-AzKeyVaultKey `
  -VaultName ${AKV_NAME} `
  -Name ${ACR_ENC_KEY_NAME}
$ACR_ENC_KEY

$ACR_ENC_KEY_ID = $ACR_ENC_KEY.Id

$ACR_ENC_KEY_ID=(echo $ACR_ENC_KEY_ID | sed -e "s/\/[^/]*$//")
$ACR_ENC_KEY_ID


echo '
# ===============================================================================
# Get User AMI
# ==============================================================================='

$identity=Get-AzUserAssignedIdentity -ResourceGroupName ${ARG_NAME} -Name ${AMI_NAME}

echo "User AMI is", $identity


echo '
# ===============================================================================
# Create ACR
# ==============================================================================='


az acr create `
  --resource-group ${ARG_NAME} `
  --name $ACR_NAME `
  --identity $identity.id `
  --key-encryption-key $ACR_ENC_KEY_ID `
  --admin-enabled true `
  --sku Premium 


  # TODO Maybe use basic, price is 
# az acr create `
#   --resource-group ${ARG_NAME} `
#   --name $ACR_NAME `
#   --sku Basic
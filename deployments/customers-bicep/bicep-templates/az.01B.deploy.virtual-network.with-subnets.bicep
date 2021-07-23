

/*

deployments/customers/02B_deploy_vnet_subnet_for_app_gw.ps1

deployments/customers/02B_deploy_vnet_subnets_for_aci.ps1

*/

var m_subnets_app_gw = []
var m_subnets_aci = []
var m_subnets = concat(m_subnets_app_gw, m_subnets_aci)

/*****************************************************************************************
**** Deployment
*****************************************************************************************/
module deploymentVnetSubnets 'az.01B.deploy.virtual-network.bicep' = {
  name: 'deploymentVnetSubnets'
  params: {
    subnets: m_subnets
  }

}


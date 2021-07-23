/*
deployments/customers/03E_deploy_container_instance.ps1
*/

/*****************************************************************************************
**** Deployment
*****************************************************************************************/
module deploymentContainerGroupDummy1 'az.03E.deploy.container-group.bicep' = {
  name: 'deploymentContainerGroupDummy1'
  params: {

  }
  
}

module deploymentContainerGroupDummy2 'az.03E.deploy.container-group.bicep' = {
  name: 'deploymentContainerGroupDummy2'
  params: {

  }
  
}


output ipAddresses array = [
  deploymentContainerGroupDummy1.outputs.ipAddress
  deploymentContainerGroupDummy2.outputs.ipAddress
] 


var locationShortName = 'weu'
var locationLongName = 'westeurope'

var m_backendPoolsCustomers = [for i in range(0,10): {
  name: 'my-rg-${i}' 
}]

output nsgs array = m_backendPoolsCustomers
output hello string = 'Hello World!'
output myResourceGroup object = resourceGroup()


@description('Customers routing rules, listeners, backend pools to preallocate.')
@maxValue(97) // 100 is max: 97 is for customers, 1 for basic, 1 for dummy, 1 for dummyApp
@minValue(0)
param customersCount int = 2

@description('Next customers ID prefix string.')
param lastCustomerId int = 2120

var customers = [for i in range(0,customersCount): {
   id: format('{0:D9}', lastCustomerId + i) 
}]

output customersPrefix array = customers
// After starting deploy.cli.ps1 go to see arm-templates/azuredeploy.json

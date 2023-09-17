
@description('Location for all resources.')
param location string = resourceGroup().location

var virtualNetworkName = 'hubvnet01'
var subnetName ='infra'



resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.2.0/24'
           
        }
      }
    ]
  }
}


// Creates a KeyVault with Private Link Endpoint
@description('The Azure Region to deploy the resources into')
param location string = resourceGroup().location


@description('The name of the Key Vault')
param keyvaultName string





resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyvaultName
  location: location
  //tags: tags
  properties: {
    createMode: 'default'
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    enableRbacAuthorization: true
    enablePurgeProtection: true

    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: 7
    tenantId: subscription().tenantId
  }
}

resource kv1 'Microsoft.KeyVault/vaults/secrets@2023-02-01' =  {
   name: 'ind1'
   parent: keyVault
   properties: {
     attributes: {
       enabled: true
        
     }
       value: 'india11'
      
   }
  
}

output keyvaultId string = keyVault.id

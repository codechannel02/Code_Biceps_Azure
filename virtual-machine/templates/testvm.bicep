@description('location')
param location string = resourceGroup().location

param subscriptionName string

param imageSubscriptionID string

param adminusername string

param adminpassword string = 'P@ssw0rd@123'

param osdisksize int = 128

param vmSKU string = 'Standard_D2s_V3'

param osDisktype string = 'StandardSSD_LRS'

param vmResourceName string

param image string

//var imageid = 

var operatingSystemType = (contains(image, 'rhel') == true  || contains(image, 'orcl') == true ) ? 'Linux' : 'Windows'


param datadisk array

param vmVnetRg string

param vmVnet string

param subnet string

param ipallocation string

param vmip array
param backuprequired bool

var subnet_id = resourceId(vmVnetRg,'Microsoft.Network/virtualNetworks/subnet',vmVnet,subnet)

var vmName = vmResourceName

var backupLocation = startsWith(location,'east')? 'EastUS' : 'WestUS'

var backuptag = '${backupLocation}_${subscriptionName}'

var backupTagEnabledBlock = {

  Backup : backuptag
}


var backupTagDisableBloxk = {}

var backupTagFinalBlock = (backuprequired) ? backupTagEnabledBlock : backupTagDisableBloxk

resource static_nic_array 'Microsoft.Network/networkInterfaces@2021-02-01' = if (ipallocation == 'Static') {
  
    name: 'NIC-${vmName}s-01'
    location: location
    properties: {
       ipConfigurations: [for (item,i) in vmip: {
         name: 'ipconfig${vmName}0${i+1}'
         properties: {
           privateIPAllocationMethod: ipallocation
           privateIPAddress: vmip[i]
           primary: (i == 0) ? true : false
            subnet: {
               id: subnet_id
            }
         }
       }]
    }
}

resource dynamic_nic_array 'Microsoft.Network/networkInterfaces@2021-02-01' = if (ipallocation == 'Dynamic') {
  
    name: 'NIC-${vmName}s-01'
    location: location
    properties: {
       ipConfigurations: [for (item,i) in vmip: {
         name: 'ipconfig${vmName}0${i+1}'
         properties: {
           privateIPAllocationMethod: 'Dynamic'
           privateIPAddress: vmip[i]
           primary: (i == 0) ? true : false
            subnet: {
               id: subnet_id
            }
         }
       }]
    }
}

resource vm_resource 'Microsoft.Compute/virtualMachines@2022-11-01' = {

    name: vmName
    location: location
    tags: backupTagFinalBlock
    identity: {
      
       type: 'SystemAssigned'

    }
    properties: {
       hardwareProfile: {
         vmSize: vmSKU
       }
       diagnosticsProfile: {
         bootDiagnostics: {
           enabled: false
         }
       }

       networkProfile: {
         networkInterfaces: [
           {
             id: (ipallocation == 'Static') ? (static_nic_array.id) : (dynamic_nic_array.id)

           }
         ]
       }
       osProfile: {
         computerName: vmName
         adminPassword: adminpassword
         adminUsername: adminusername
         allowExtensionOperations: true

       }
       securityProfile: {
         encryptionAtHost: true
       }
       storageProfile: {
         imageReference: {
           id: image
            
         }
          osDisk: {
             caching: 'ReadWrite'
             createOption: 'FromImage'
             diskSizeGB: osdisksize
             managedDisk: {
               storageAccountType: osDisktype
             }
              osType: operatingSystemType
          }
           dataDisks: [for (item,i) in datadisk : {
              diskSizeGB: item.disksize
              lun: int(i+1)
              createOption: 'Empty'
              managedDisk: {
                 storageAccountType: item.disktype
              }
           }]
       }
    
    }
}

param djpassword string = 'P@ssw0rd'
param djgroup string = ''
param djstraccount string
param djcont string

param djkey string

param region string

var regionPrefix = substring(region ,0,4)


var cspub = (operatingSystemType == 'Linux') ? 'Microsoft.Azure.Extensions' : 'Microsoft.Compute'
var cshadver =  (operatingSystemType == 'Linux') ? '2.1' : '1.10'
var csexttype = (operatingSystemType == 'Linux') ? 'CustomScript' : 'CustomScriptExtension'
var winscript = 'https://${djstraccount}.blob${environment().suffixes.storage}/${djcont}/windom.ps1'
var linscript = 'https://${djstraccount}.blob${environment().suffixes.storage}/${djcont}/lindom.ps1'

resource dj_exten 'Microsoft.Compute/virtualMachines/extensions@2022-11-01' = if(operatingSystemType == 'Linux') {
    name: 'domain linux'
     location: location
     parent: vm_resource
     properties: {
       publisher: cspub
        type: csexttype
        typeHandlerVersion: cshadver
        autoUpgradeMinorVersion: true
        protectedSettings: {
           commandTOExecute : 'sh lindom.sh ${regionPrefix} ${djpassword} ${djgroup}'
           storageAccountName: djstraccount
           storageAccountKay:djkey
           fileUris :[
             linscript
           ]
        }
     }

}



resource dj_exten_w 'Microsoft.Compute/virtualMachines/extensions@2022-11-01' = if(operatingSystemType == 'Windows') {
    name: 'domain windows'
     location: location
     parent: vm_resource
     properties: {
       publisher: cspub
        type: csexttype
        typeHandlerVersion: cshadver
        autoUpgradeMinorVersion: true
        protectedSettings: {
           commandTOExecute : 'powershell -ExecutionPolicy Unrestricted -File windom.ps1 -domainPassword \'${djpassword}\' -addgrp ${djgroup}'
           storageAccountName: djstraccount
           storageAccountKay:djkey
           fileUris :[
             linscript
           ]
        }
     }

}

output vm_name string = vm_resource.name
output vm_id string = vm_resource.id

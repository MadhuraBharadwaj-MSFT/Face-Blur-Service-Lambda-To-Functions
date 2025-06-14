// Storage Private Endpoint Module

@description('Location for all resources')
param location string = resourceGroup().location

@description('Tags for the resources')
param tags object = {}

@description('Virtual Network name')
param virtualNetworkName string

@description('Subnet name for private endpoints')
param subnetName string

@description('Storage account name')
param resourceName string

@description('Enable blob private endpoint')
param enableBlob bool = true

@description('Enable queue private endpoint')
param enableQueue bool = false

@description('Enable table private endpoint')
param enableTable bool = false

// Get existing resources
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: virtualNetworkName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: subnetName
  parent: virtualNetwork
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: resourceName
}

// Private DNS Zone for Blob
resource blobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enableBlob) {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
  tags: tags
}

// Private DNS Zone VNet Link for Blob
resource blobPrivateDnsZoneVNetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (enableBlob) {
  name: '${virtualNetworkName}-link'
  parent: blobPrivateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

// Private Endpoint for Blob
resource blobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-11-01' = if (enableBlob) {
  name: '${resourceName}-blob-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${resourceName}-blob-psc'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone Group for Blob
resource blobPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-11-01' = if (enableBlob) {
  name: 'default'
  parent: blobPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: blobPrivateDnsZone.id
        }
      }
    ]
  }
}

// Private DNS Zone for Queue
resource queuePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enableQueue) {
  name: 'privatelink.queue.${environment().suffixes.storage}'
  location: 'global'
  tags: tags
}

// Private DNS Zone VNet Link for Queue
resource queuePrivateDnsZoneVNetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (enableQueue) {
  name: '${virtualNetworkName}-link'
  parent: queuePrivateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

// Private Endpoint for Queue
resource queuePrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-11-01' = if (enableQueue) {
  name: '${resourceName}-queue-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${resourceName}-queue-psc'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'queue'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone Group for Queue
resource queuePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-11-01' = if (enableQueue) {
  name: 'default'
  parent: queuePrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: queuePrivateDnsZone.id
        }
      }
    ]
  }
}

// Private DNS Zone for Table
resource tablePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enableTable) {
  name: 'privatelink.table.${environment().suffixes.storage}'
  location: 'global'
  tags: tags
}

// Private DNS Zone VNet Link for Table
resource tablePrivateDnsZoneVNetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (enableTable) {
  name: '${virtualNetworkName}-link'
  parent: tablePrivateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

// Private Endpoint for Table
resource tablePrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-11-01' = if (enableTable) {
  name: '${resourceName}-table-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${resourceName}-table-psc'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'table'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone Group for Table
resource tablePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-11-01' = if (enableTable) {
  name: 'default'
  parent: tablePrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: tablePrivateDnsZone.id
        }
      }
    ]
  }
}

// Computer Vision Module

@description('Name of the Computer Vision account')
param computerVisionName string

@description('Location for resources')
param location string = resourceGroup().location

@description('The Computer Vision pricing tier')
@allowed([
  'F0' // Free tier
  'S1' // Standard tier
])
param sku string = 'S1'

@description('The kind of Computer Vision resource to create')
param kind string = 'ComputerVision'

@description('Tags to apply to the resource')
param tags object = {}

resource computerVision 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: computerVisionName
  location: location
  kind: kind
  sku: {
    name: sku
  }
  properties: {
    apiProperties: {
      statisticsEnabled: false
    }
    publicNetworkAccess: 'Enabled'
    customSubDomainName: computerVisionName
  }
  tags: tags
}

output computerVisionName string = computerVision.name
output computerVisionEndpoint string = computerVision.properties.endpoint
output computerVisionId string = computerVision.id

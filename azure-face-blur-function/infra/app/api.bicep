// Azure Function App for Face Blur API

@description('The name of the function app')
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Tags for the function app')
param tags object = {}

@description('Application Insights name')
param applicationInsightsName string

@description('App Service Plan resource ID')
param appServicePlanId string

@description('Runtime name (e.g., node)')
param runtimeName string

@description('Runtime version (e.g., 22)')
param runtimeVersion string

@description('Storage account name')
param storageAccountName string

@description('User-assigned managed identity resource ID')
param identityId string

@description('Application settings')
param appSettings object = {}

@description('Virtual network subnet ID (optional)')
param virtualNetworkSubnetId string = ''

@description('Computer Vision endpoint')
param computerVisionEndpoint string = ''

@description('Source container name')
param sourceContainerName string = 'face-blur-source'

@description('Destination container name')
param destinationContainerName string = 'face-blur-destination'

@description('Deployment storage container name')
param deploymentStorageContainerName string

// Get existing resources
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

// Function App
resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: name
  location: location
  kind: 'functionapp,linux'
  tags: union(tags, {
    'azd-service-name': 'api'
  })
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    virtualNetworkSubnetId: !empty(virtualNetworkSubnetId) ? virtualNetworkSubnetId : null
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: 'https://${storageAccount.name}.blob.${environment().suffixes.storage}/${deploymentStorageContainerName}'
          authentication: {
            type: 'SystemAssignedIdentity'
          }
        }
      }
      runtime: {
        name: runtimeName
        version: runtimeVersion
      }
      scaleAndConcurrency: {
        maximumInstanceCount: 200
        instanceMemoryMB: 2048
      }
    }
    siteConfig: {
      appSettings: union([
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccount.name
        }
        {
          name: 'AzureWebJobsStorage__queueServiceUri'
          value: 'https://${storageAccount.name}.queue.${environment().suffixes.storage}'
        }
        {
          name: 'AzureWebJobsStorage__blobServiceUri'
          value: 'https://${storageAccount.name}.blob.${environment().suffixes.storage}'
        }
        {
          name: 'AzureWebJobsStorage__credential'
          value: 'managedidentity'
        }
        {
          name: 'AzureWebJobsStorage__clientId'
          value: reference(identityId, '2023-01-31').clientId
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'STORAGE_ACCOUNT_URL'
          value: 'https://${storageAccount.name}.blob.${environment().suffixes.storage}'
        }
        {
          name: 'SOURCE_CONTAINER_NAME'
          value: sourceContainerName
        }
        {
          name: 'DESTINATION_CONTAINER_NAME'
          value: destinationContainerName
        }
        {
          name: 'COMPUTER_VISION_ENDPOINT'
          value: computerVisionEndpoint
        }
      ], items(appSettings))
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
          'https://ms.portal.azure.com'  
        ]
        supportCredentials: false
      }
    }
  }
}

// Outputs
output SERVICE_API_NAME string = functionApp.name
output functionAppId string = functionApp.id
output functionAppName string = functionApp.name
output defaultHostName string = functionApp.properties.defaultHostName
output systemAssignedIdentityPrincipalId string = functionApp.identity.principalId

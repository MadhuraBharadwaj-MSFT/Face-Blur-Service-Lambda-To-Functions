// RBAC Role Assignments Module

@description('Storage Account name')
param storageAccountName string

@description('Application Insights name')
param appInsightsName string

@description('Managed Identity Principal ID')
param managedIdentityPrincipalId string

@description('Function App System Assigned Identity Principal ID')
param functionAppSystemIdentityPrincipalId string = ''

@description('User Identity Principal ID for testing/debugging')
param userIdentityPrincipalId string = ''

@description('Enable blob storage access')
param enableBlob bool = true

@description('Enable queue storage access')
param enableQueue bool = false

@description('Enable table storage access')
param enableTable bool = false

@description('Allow user identity principal access')
param allowUserIdentityPrincipal bool = true

// Get existing resources
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

// Storage Blob Data Contributor role for managed identity
resource blobDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableBlob) {
  name: guid(storageAccount.id, managedIdentityPrincipalId, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Storage Queue Data Contributor role for managed identity
resource queueDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableQueue) {
  name: guid(storageAccount.id, managedIdentityPrincipalId, '974c5e8b-45b9-4653-ba55-5f855dd0fb88')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '974c5e8b-45b9-4653-ba55-5f855dd0fb88') // Storage Queue Data Contributor
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Storage Table Data Contributor role for managed identity
resource tableDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableTable) {
  name: guid(storageAccount.id, managedIdentityPrincipalId, '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3') // Storage Table Data Contributor
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Storage Blob Data Contributor role for Function App System Assigned Identity (for deployment)
resource functionAppBlobDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableBlob && !empty(functionAppSystemIdentityPrincipalId)) {
  name: guid(storageAccount.id, functionAppSystemIdentityPrincipalId, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe', 'systemassigned')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: functionAppSystemIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Storage Queue Data Contributor role for Function App System Assigned Identity (for queue triggers)
resource functionAppQueueDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableQueue && !empty(functionAppSystemIdentityPrincipalId)) {
  name: guid(storageAccount.id, functionAppSystemIdentityPrincipalId, '974c5e8b-45b9-4653-ba55-5f855dd0fb88', 'systemassigned')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '974c5e8b-45b9-4653-ba55-5f855dd0fb88') // Storage Queue Data Contributor
    principalId: functionAppSystemIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// User identity access (for testing/debugging)
resource userBlobDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableBlob && allowUserIdentityPrincipal && !empty(userIdentityPrincipalId)) {
  name: guid(storageAccount.id, userIdentityPrincipalId, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe', 'user')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: userIdentityPrincipalId
    principalType: 'User'
  }
}

resource userQueueDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableQueue && allowUserIdentityPrincipal && !empty(userIdentityPrincipalId)) {
  name: guid(storageAccount.id, userIdentityPrincipalId, '974c5e8b-45b9-4653-ba55-5f855dd0fb88', 'user')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '974c5e8b-45b9-4653-ba55-5f855dd0fb88') // Storage Queue Data Contributor
    principalId: userIdentityPrincipalId
    principalType: 'User'
  }
}

resource userTableDataContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableTable && allowUserIdentityPrincipal && !empty(userIdentityPrincipalId)) {
  name: guid(storageAccount.id, userIdentityPrincipalId, '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3', 'user')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3') // Storage Table Data Contributor
    principalId: userIdentityPrincipalId
    principalType: 'User'
  }
}

// Monitoring Contributor role for Application Insights
resource monitoringContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(applicationInsights.id, managedIdentityPrincipalId, 'f1a07417-d97a-45cb-824c-7a7467783830')
  scope: applicationInsights
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'f1a07417-d97a-45cb-824c-7a7467783830') // Monitoring Contributor
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

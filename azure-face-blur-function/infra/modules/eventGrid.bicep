// Event Grid module for Blob to Queue notifications

@description('Storage Account name')
param storageAccountName string

@description('Storage queue name')
param queueName string

@description('Source container name to monitor')
param sourceContainerName string

@description('Location for resources')
param location string

@description('Tags for resources')
param tags object = {}

// Get existing storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

// Create Event Grid System Topic for the storage account
resource storageEventGridTopic 'Microsoft.EventGrid/systemTopics@2022-06-15' = {
  name: 'st-${storageAccountName}-topic'
  location: location
  tags: tags
  properties: {
    source: storageAccount.id
    topicType: 'Microsoft.Storage.StorageAccounts'
  }
}

// Event Grid Subscription to send blob created events to storage queue
resource blobCreatedEventSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2022-06-15' = {
  parent: storageEventGridTopic
  name: 'blob-created-subscription'
  properties: {
    destination: {
      endpointType: 'StorageQueue'
      properties: {
        resourceId: storageAccount.id
        queueName: queueName
      }
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
      ]
      advancedFilters: [
        {
          operatorType: 'StringContains'
          key: 'subject'
          values: [
            '/blobServices/default/containers/${sourceContainerName}/blobs/'
          ]
        }
      ]
    }
    retryPolicy: {
      maxDeliveryAttempts: 3
      eventTimeToLiveInMinutes: 1440
    }
  }
}

// Outputs
output eventGridTopicName string = storageEventGridTopic.name
output eventSubscriptionName string = blobCreatedEventSubscription.name

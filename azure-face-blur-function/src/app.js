/*! 
 * Face Blur Function - Migrated from AWS Lambda
 * SPDX-License-Identifier: MIT-0
 */

'use strict';

const { app } = require('@azure/functions');
const { detectFaces } = require('./detectFaces');
const { blurFaces } = require('./blurFaces');
const { BlobServiceClient } = require('@azure/storage-blob');
const { DefaultAzureCredential } = require('@azure/identity');

// Storage Queue trigger - maintains AWS Lambda architecture: Blob → Queue → Function
app.storageQueue('processImageQueue', {
    queueName: 'image-processing-queue',
    connection: 'AzureWebJobsStorage',
    handler: async (queueItem, context) => {
        context.log('Queue trigger function processed work item:', queueItem);
        
        try {
            // Parse the Event Grid message
            let eventData;
            if (typeof queueItem === 'string') {
                eventData = JSON.parse(queueItem);
            } else {
                eventData = queueItem;
            }
            
            // Extract blob information from Event Grid notification
            const subject = eventData.subject || eventData.data?.url;
            if (!subject) {
                context.log('No subject found in queue message, skipping');
                return;
            }
            
            // Parse blob name from subject: /blobServices/default/containers/face-blur-source/blobs/image.jpg
            const blobPathMatch = subject.match(/\/containers\/([^\/]+)\/blobs\/(.+)$/);
            if (!blobPathMatch) {
                context.log('Could not parse blob path from subject:', subject);
                return;
            }
            
            const containerName = blobPathMatch[1];
            const blobName = blobPathMatch[2];
            
            context.log(`Processing blob: ${blobName} from container: ${containerName}`);
            
            // Only process images from the source container
            if (containerName !== process.env.SOURCE_CONTAINER_NAME) {
                context.log(`Skipping blob from container: ${containerName}`);
                return;
            }
            
            // Initialize blob service with managed identity
            const storageAccountUrl = process.env.STORAGE_ACCOUNT_URL;
            const credential = new DefaultAzureCredential();
            const blobServiceClient = new BlobServiceClient(storageAccountUrl, credential);
            
            // Get blob client
            const containerClient = blobServiceClient.getContainerClient(containerName);
            const blobClient = containerClient.getBlobClient(blobName);
            
            // Download the image
            context.log('Downloading image from blob storage...');
            const downloadResponse = await blobClient.download();
            const imageBuffer = await streamToBuffer(downloadResponse.readableStreamBody);
            
            // Detect faces in the image
            context.log('Detecting faces in image...');
            const faces = await detectFaces(imageBuffer, context);
            
            if (faces && faces.length > 0) {
                context.log(`Found ${faces.length} face(s), blurring...`);
                
                // Blur faces in the image
                const blurredImageBuffer = await blurFaces(imageBuffer, faces, context);
                
                // Upload the processed image to destination container
                const destinationContainerClient = blobServiceClient.getContainerClient(process.env.DESTINATION_CONTAINER_NAME);
                const destinationBlobClient = destinationContainerClient.getBlobClient(blobName);
                
                context.log('Uploading processed image...');
                await destinationBlobClient.upload(blurredImageBuffer, blurredImageBuffer.length, {
                    blobHTTPHeaders: {
                        blobContentType: 'image/jpeg'
                    }
                });
                
                context.log(`Successfully processed and uploaded: ${blobName}`);
            } else {
                context.log('No faces detected in image, skipping processing');
                
                // Still upload the original image to destination
                const destinationContainerClient = blobServiceClient.getContainerClient(process.env.DESTINATION_CONTAINER_NAME);
                const destinationBlobClient = destinationContainerClient.getBlobClient(blobName);
                
                await destinationBlobClient.upload(imageBuffer, imageBuffer.length, {
                    blobHTTPHeaders: {
                        blobContentType: 'image/jpeg'
                    }
                });
                
                context.log(`Uploaded original image (no faces): ${blobName}`);
            }
            
        } catch (error) {
            context.log('Error processing image:', error);
            throw error;
        }
    }
});

// Helper function to convert stream to buffer
async function streamToBuffer(readableStream) {
    const chunks = [];
    for await (const chunk of readableStream) {
        chunks.push(chunk);
    }
    return Buffer.concat(chunks);
}

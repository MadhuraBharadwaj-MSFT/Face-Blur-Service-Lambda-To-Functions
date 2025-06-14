/*! 
 * Face Blur Function - Migrated from AWS Lambda
 * SPDX-License-Identifier: MIT-0
 */

'use strict';

const { DefaultAzureCredential } = require('@azure/identity');
const { BlobServiceClient } = require('@azure/storage-blob');
const gm = require('gm').subClass({ imageMagick: process.env.LOCAL_TEST === 'true' });

const blurFaces = async (containerName, blobName, faceDetails) => {
  try {
    // Get the blob content
    const credential = new DefaultAzureCredential();
    const blobServiceClient = new BlobServiceClient(
      process.env.STORAGE_ACCOUNT_URL,
      credential
    );
    
    const containerClient = blobServiceClient.getContainerClient(containerName);
    const blobClient = containerClient.getBlobClient(blobName);
    const downloadBlockBlobResponse = await blobClient.download();
    
    // Convert stream to buffer
    const chunks = [];
    const stream = downloadBlockBlobResponse.readableStreamBody;
    
    return new Promise((resolve, reject) => {
      stream.on('data', (chunk) => chunks.push(Buffer.from(chunk)));
      stream.on('error', (err) => reject(err));
      stream.on('end', () => {
        const buffer = Buffer.concat(chunks);
        
        // Process the image with GraphicsMagick
        let img = gm(buffer);
        
        img.size(function(err, dimensions) {
          if (err) {
            console.error('Error getting image dimensions:', err);
            return reject(err);
          }
          
          console.log('Image size:', dimensions);
          
          // Apply blur to each detected face
          faceDetails.forEach((faceDetail) => {
            const box = faceDetail.BoundingBox;
            const width = box.Width * dimensions.width;
            const height = box.Height * dimensions.height;
            const left = box.Left * dimensions.width;
            const top = box.Top * dimensions.height;
            
            // Apply blur to the face region
            img.region(width, height, left, top).blur(0, 70);
          });
          
          // Convert processed image to buffer
          img.toBuffer((err, buffer) => {
            if (err) {
              console.error('Error converting image to buffer:', err);
              return reject(err);
            }
            
            resolve(buffer);
          });
        });
      });
    });
  } catch (error) {
    console.error('Error blurring faces:', error);
    throw error;
  }
};

module.exports = { blurFaces };

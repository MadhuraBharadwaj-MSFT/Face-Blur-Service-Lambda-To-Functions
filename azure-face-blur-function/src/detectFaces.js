/*! 
 * Face Blur Function - Migrated from AWS Lambda
 * SPDX-License-Identifier: MIT-0
 */

'use strict';

const { DefaultAzureCredential } = require('@azure/identity');
const { ComputerVisionClient } = require('@azure/cognitiveservices-computervision');
const { ApiKeyCredentials } = require('@azure/ms-rest-js');
const { appInsights } = require('@azure/functions');

// Configure Computer Vision client
const getComputerVisionClient = () => {
  // If using Azure Key Vault for keys, this would be more complex
  if (process.env.COMPUTER_VISION_KEY) {
    // Use API key authentication if provided
    return new ComputerVisionClient(
      new ApiKeyCredentials({ inHeader: { 'Ocp-Apim-Subscription-Key': process.env.COMPUTER_VISION_KEY } }),
      process.env.COMPUTER_VISION_ENDPOINT
    );
  } else {
    // Use Managed Identity (preferred in production)
    return new ComputerVisionClient(
      new DefaultAzureCredential(),
      process.env.COMPUTER_VISION_ENDPOINT
    );
  }
};

// Detect faces in an image stored in Azure Blob Storage
const detectFaces = async (containerName, blobName) => {
  try {
    const client = getComputerVisionClient();
    
    // Create URL for the blob - assumes proper environment variables are set
    const blobUrl = `${process.env.STORAGE_ACCOUNT_URL}/${containerName}/${blobName}`;
    
    console.log(`Detecting faces in: ${blobUrl}`);
    appInsights.defaultClient.trackTrace({ message: `Detecting faces in: ${blobUrl}` });
    
    // Call the Computer Vision API to detect faces
    const options = {
      visualFeatures: ['Faces'],
    };
    
    const result = await client.analyzeImage(blobUrl, options);
    
    // Transform the result to match the format expected by the blurFaces function
    // This provides compatibility with the migrated AWS code
    if (result.faces && result.faces.length > 0) {
      return result.faces.map(face => ({
        BoundingBox: {
          Width: face.faceRectangle.width / result.metadata.width,
          Height: face.faceRectangle.height / result.metadata.height,
          Left: face.faceRectangle.left / result.metadata.width,
          Top: face.faceRectangle.top / result.metadata.height
        }
      }));
    }
    
    return [];
  } catch (error) {
    console.error('Error detecting faces:', error);
    appInsights.defaultClient.trackException({ exception: error });
    // Return empty array on error to be consistent with original code
    return [];
  }
};

module.exports = { detectFaces };

/*! 
 * Face Blur Function - Migrated from AWS Lambda
 * SPDX-License-Identifier: MIT-0
 */

'use strict';

const { describe, it, beforeEach, afterEach, expect, jest } = require('@jest/globals');
const path = require('path');

// Mock the dependencies
jest.mock('@azure/identity', () => ({
  DefaultAzureCredential: jest.fn().mockImplementation(() => ({}))
}));

jest.mock('@azure/storage-blob', () => {
  const mockUpload = jest.fn().mockResolvedValue({});
  const mockDownload = jest.fn().mockResolvedValue({
    readableStreamBody: {
      on: (event, callback) => {
        if (event === 'data') {
          callback(Buffer.from('test-image'));
        } else if (event === 'end') {
          callback();
        }
      }
    }
  });
  
  return {
    BlobServiceClient: jest.fn().mockImplementation(() => ({
      getContainerClient: jest.fn().mockImplementation(() => ({
        getBlockBlobClient: jest.fn().mockImplementation(() => ({
          upload: mockUpload
        })),
        getBlobClient: jest.fn().mockImplementation(() => ({
          download: mockDownload
        }))
      }))
    }))
  };
});

jest.mock('@azure/cognitiveservices-computervision', () => {
  return {
    ComputerVisionClient: jest.fn().mockImplementation(() => ({
      analyzeImage: jest.fn().mockResolvedValue({
        faces: [
          {
            faceRectangle: {
              width: 100,
              height: 100,
              left: 50,
              top: 50
            }
          }
        ],
        metadata: {
          width: 500,
          height: 500
        }
      })
    }))
  };
});

jest.mock('@azure/ms-rest-js', () => ({
  ApiKeyCredentials: jest.fn().mockImplementation(() => ({}))
}));

jest.mock('gm', () => {
  const mockToBuffer = jest.fn().mockImplementation((callback) => {
    callback(null, Buffer.from('processed-image'));
  });
  
  const mockRegion = jest.fn().mockReturnThis();
  const mockBlur = jest.fn().mockReturnThis();
  
  const mockSize = jest.fn().mockImplementation(function(callback) {
    callback(null, { width: 500, height: 500 });
    return this;
  });
  
  const gmMock = jest.fn().mockImplementation(() => ({
    size: mockSize,
    region: mockRegion,
    blur: mockBlur,
    toBuffer: mockToBuffer
  }));
  
  gmMock.subClass = jest.fn().mockReturnValue(gmMock);
  
  return gmMock;
});

// Set up environment variables
beforeEach(() => {
  process.env.STORAGE_ACCOUNT_URL = 'https://teststorage.blob.core.windows.net';
  process.env.SOURCE_CONTAINER_NAME = 'face-blur-source';
  process.env.DESTINATION_CONTAINER_NAME = 'face-blur-destination';
  process.env.COMPUTER_VISION_ENDPOINT = 'https://testcompvision.cognitiveservices.azure.com/';
  process.env.COMPUTER_VISION_KEY = 'test-key';
  process.env.LOCAL_TEST = 'true';
});

afterEach(() => {
  jest.resetModules();
});

describe('Face Blur Function', () => {
  it('should process an image with faces', async () => {
    // Load test event
    const testEvent = require('./testEvent.json');
    const testMessage = testEvent.Records[0].body;
    
    // Import the function
    const functionHandler = require('../src/blurFunction/index');
    
    // Mock context
    const context = {
      log: jest.fn(),
      log.error: jest.fn()
    };
    
    // Call the function
    await functionHandler(context, testMessage);
    
    // Verify the log was called
    expect(context.log).toHaveBeenCalled();
  });
});

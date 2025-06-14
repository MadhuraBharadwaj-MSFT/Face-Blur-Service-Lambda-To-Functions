# Azure Face Blur Function

A serverless face blurring service migrated from AWS Lambda to Azure Functions. This application automatically blurs faces in images uploaded to Azure Storage using **managed identity authentication** for secure, production-ready deployment.

## 🏗️ Architecture

The solution uses a **secure, managed identity-based architecture** with:

- **Azure Functions** (FlexConsumption) - Serverless compute with automatic scaling
- **Azure Storage Account** - Blob storage for images and queue for event processing
- **Azure Computer Vision** - AI-powered face detection service
- **Azure Event Grid** - Blob creation events trigger queue-based processing
- **Azure Application Insights** - Comprehensive monitoring and logging
- **Managed Identity** - Keyless authentication for all Azure service connections

## 🔄 Processing Flow

1. Image uploaded to `face-blur-source` container
2. Event Grid sends blob creation event to `image-processing-queue`
3. Azure Function triggered by queue message (maintains AWS Lambda architecture pattern)
4. Function downloads image using managed identity, detects faces via Computer Vision
5. Applies blur effect to detected faces and uploads to `face-blur-destination` container

## 🔐 Security Features

- **Zero connection strings** - Uses managed identity for all Azure service authentication
- **Shared key access disabled** - Storage account configured for managed identity only
- **HTTPS enforcement** - All communication encrypted in transit
- **RBAC permissions** - Principle of least privilege access model
- **No secrets in code** - All authentication handled by Azure Active Directory

## 🚀 Deployment

### Using Azure Developer CLI (azd)

1. Log in to Azure:
   ```bash
   azd auth login
   ```

2. Initialize a new environment:
   ```bash
   azd init
   ```

3. Deploy the solution:
   ```bash
   azd up
   ```

### Using Azure CLI

1. Create a resource group:
   ```bash
   az group create --name <resource-group-name> --location <location>
   ```

2. Deploy the Bicep template:
   ```bash
   az deployment group create \
     --resource-group <resource-group-name> \
     --template-file infra/main.bicep \
     --parameters infra/main.parameters.json
   ```

3. Deploy the function app:
   ```bash
   cd src
   func azure functionapp publish <function-app-name> --javascript
   ```

## Testing

1. Upload an image to the source container in your storage account
2. The function will be triggered and process the image
3. Check the destination container for the processed image with blurred faces

## Local Development

1. Clone this repository
2. Install dependencies:
   ```bash
   cd azure-face-blur-function/src
   npm install
   ```
3. Install ImageMagick for your platform

4. Update the `local.settings.json` file with your Azure Storage and Computer Vision details

5. Start the function locally:
   ```bash
   func start
   ```

## Local Testing

1. Run the tests:
   ```bash
   cd azure-face-blur-function
   npm test
   ```

## License

MIT-0

Deploy resources to Azure

# Azure Deployment Guide - Best Practices

## Deployment Approach

This project uses Azure Developer CLI (azd) for deployment. The azd tool streamlines the deployment process by handling infrastructure provisioning, application building, and deployment in a single command.

## Pre-Deployment Checklist

Before deploying, ensure:
- You have the latest Azure CLI and Azure Developer CLI installed
- You are logged in to Azure (`az login`)
- You have selected the correct subscription (`az account set --subscription <subscription-id>`)
- Your infrastructure files in the `infra/` folder are correctly set up and validated
- Your application code is ready for deployment

## Infrastructure Deployment Best Practices

Our infrastructure follows these principles:
- Uses AVM (Azure Verified Modules) for consistent, secure resource deployment
- Implements modular Bicep files organized by resource type
- Applies least-privilege RBAC with dedicated modules
- Uses managed identities for secure service-to-service authentication
- Configures proper monitoring with Application Insights and Log Analytics

## Deployment Steps

1. **Environment Setup**
   ```bash
   # Initialize azd environment
   azd init
   
   # or use an existing environment
   azd env select <environment-name>

   At the end, generate a deployment summary report in the reports folder.
   Also, update the status report file with the status of the deployment step.
   ```
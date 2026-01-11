# Serverless Image Resizer with Azure Function

A fully **event-driven, serverless** demo on Azure:  
Upload any image → Azure Event Grid detects it → Triggers an Azure Function → Resizes to thumbnail → Saves to storage → Thumbnails appear live in a static gallery!

Built with **Terraform** — 100% Infrastructure as Code.

## Live Demo Flow
1. Upload image to `originals` container in Storage Account
2. Event Grid fires `BlobCreated` event
3. Azure Function resizes image (Python + Pillow)
4. Thumbnail saved to `thumbnails` container
5. Static website (`$web`) shows updated gallery

## Architecture
- Azure Storage Account (source + thumbnails + static site)
- Event Grid Subscription (BlobCreated trigger)
- Azure Function (Consumption plan, Python 3.11)
- Static Website Hosting

## How to Run Locally
1. `terraform init`
2. `terraform plan`
3. `terraform apply`
4. Upload image to `originals` container
5. Wait 10–60s → Refresh static website URL → See thumbnail!

Static site URL: https://YOUR_STORAGE_ACCOUNT.z13.web.core.windows.net/

## Tech Stack
- Terraform (AzureRM provider)
- Azure Functions (Python)
- Azure Event Grid
- Azure Storage (Static Website + Blob)
- Pillow (image processing)

Perfect for learning serverless, event-driven patterns on Azure.

Built with ❤️ as a demo/portfolio project.

#Azure #Terraform #AzureFunctions #Serverless #EventDriven #CloudNative
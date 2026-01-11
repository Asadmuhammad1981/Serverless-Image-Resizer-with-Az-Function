resource "azurerm_resource_group" "function-rg" {
    name = "function-rg"
    location = "westeurope"
}


# 1. Storage Account
resource "azurerm_storage_account" "sa" {
  name                     = "imgresizer${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.function-rg.name
  location                 = azurerm_resource_group.function-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = {
    purpose = "image-resizer-demo"
  }
}

# 1a. Static Website Configuration
resource "azurerm_storage_account_static_website" "static_site" {
  storage_account_id = azurerm_storage_account.sa.id
  index_document     = "index.html"
}

# 2. Containers
resource "azurerm_storage_container" "originals" {
  name                  = "originals"
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "blob"   # Public read for demo
}

resource "azurerm_storage_container" "thumbnails" {
  name                  = "thumbnails"
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "blob"   # Public read for gallery
}

resource "azurerm_storage_blob" "index_html" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = "$web"   # Special built-in container
  type                   = "Block"
  content_type           = "text/html"
  source                 = "${path.module}/index.html"   # Local path to your HTML file
  depends_on             = [azurerm_storage_account_static_website.static_site]
}

# 3. Service Plan (Serverless)
resource "azurerm_service_plan" "plan" {
  name                = "asp-imgresizer"
  resource_group_name = azurerm_resource_group.function-rg.name
  location            = azurerm_resource_group.function-rg.location
  os_type             = "Linux"
  sku_name            = "Y1"   # Consumption = pay-per-execution
}

# 4. Linux Function App (Python 3.11)
resource "azurerm_linux_function_app" "func" {
  name                       = "func-imgresizer-${random_string.suffix.result}"
  resource_group_name        = azurerm_resource_group.function-rg.name
  location                   = azurerm_resource_group.function-rg.location
  service_plan_id            = azurerm_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "AzureWebJobsStorage"      = azurerm_storage_account.sa.primary_connection_string
    "THUMBNAIL_CONTAINER"      = azurerm_storage_container.thumbnails.name
  }
}

resource "time_sleep" "waitclear_for_function_ready" {
  create_duration = "300s"   # 60 seconds - adjust if needed (30–90s usually enough)
  depends_on      = [azurerm_linux_function_app.func]
}
# # 5. Event Grid Subscription (BlobCreated → Function)

resource "azurerm_eventgrid_event_subscription" "to_function" {
  name  = "blob-upload-to-resizer"
  scope = azurerm_storage_account.sa.id

  included_event_types = ["Microsoft.Storage.BlobCreated"]

  azure_function_endpoint {
    function_id = "${azurerm_linux_function_app.func.id}/functions/ResizeImage"
  }

  subject_filter {
    subject_begins_with = "/blobServices/default/containers/originals/blobs/"
  }

  retry_policy {
    event_time_to_live = 1440   # 24 hours
    max_delivery_attempts = 30
  }
  
  lifecycle {
    ignore_changes = [azure_function_endpoint]
  }
}

# Random suffix for unique names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
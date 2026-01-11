terraform {
    required_version = ">= 1.0"
    
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.57.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
   features {}
   subscription_id = "8b0422c9-d3b4-4ad5-b676-1cd162a61f87"  
}
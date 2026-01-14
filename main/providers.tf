terraform {
  required_version = "~> 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.74" #, < 5.0.0" #"~> 3.74"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Backend configuration for remote state storage in Azure
  # Values are provided via -backend-config flags in GitHub Actions
  backend "azurerm" {
    
  }

}

provider "azurerm" {
  subscription_id = "${var.subscription_id}"  
  storage_use_azuread = true # Enable Azure AD authentication instead of storage account keys for storage operations  
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
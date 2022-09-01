terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.20.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "ghost-blog" {
  name     = "ghost-blog"
  location = "West Europe"
}


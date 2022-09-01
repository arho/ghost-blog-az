terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.20.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tf-backend"
    storage_account_name = "ccaztfmainback3352bdbe2"
    container_name       = "tfbackends"
    key                  = "envinit.tfstate"
  }
}

provider "azurerm" {
  features {}
}


# Configure RG and Storage Account
resource "azurerm_resource_group" "tf-backend" {
  name     = "tf-backend"
  location = "West Europe"

  tags = {
    function = "terraform backends"
  }
}

resource "azurerm_storage_account" "tf-backend-sa" {
  name                     = "ccaztfmainback3352bdbe2"
  resource_group_name      = azurerm_resource_group.tf-backend.name
  location                 = azurerm_resource_group.tf-backend.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    function = azurerm_resource_group.tf-backend.tags.function
  }
}

resource "azurerm_storage_container" "tf-backend-bc" {
  name                  = "tfbackends"
  storage_account_name  = azurerm_storage_account.tf-backend-sa.name
  container_access_type = "private"
}


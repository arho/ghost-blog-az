terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.20.0"
    }
    azapi = {
      source = "Azure/azapi"
      version = "0.5.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tf-backend"
    storage_account_name = "ccaztfmainback3352bdbe2"
    container_name       = "tfbackends"
    key                  = "ghostdeployment.tfstate"
  }  
}

provider "azurerm" {
  features {}
}

variable "mysql-login" {
  type = string
  description = "Login to authenticate to MySQL"
}
variable "mysql-password" {
  type = string
  description = "Password to authenticate to MySQL"
}




resource "azurerm_resource_group" "ghost-blog" {
  name     = "ghost-blog"
  location = "West Europe"
}

resource "azurerm_log_analytics_workspace" "ghost-law" {
  name                = "ghost-law"
  location            = azurerm_resource_group.ghost-blog.location
  resource_group_name = azurerm_resource_group.ghost-blog.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}


resource "azapi_resource" "acme-ghost" {
  type = "Microsoft.App/managedEnvironments@2022-03-01"
  name = "acme-ghost"
  parent_id = azurerm_resource_group.ghost-blog.id
  location = azurerm_resource_group.ghost-blog.location
  body = jsonencode({
    properties = {
      appLogsConfiguration = {
        destination = "log-analytics"
        logAnalyticsConfiguration = {
          customerId = azurerm_log_analytics_workspace.ghost-law.workspace_id
          sharedKey = azurerm_log_analytics_workspace.ghost-law.primary_shared_key
        }
      }
      zoneRedundant = false
    }
  })
}






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


# MySQL DB
resource "azurerm_mysql_server" "ghost-mysql" {
  name                = "ghost-mysqlserver"
  location            = azurerm_resource_group.ghost-blog.location
  resource_group_name = azurerm_resource_group.ghost-blog.name

  administrator_login          = var.mysql-login
  administrator_login_password = var.mysql-password

  sku_name   = "B_Gen5_2"
  storage_mb = 5120
  version    = "8.0"

  auto_grow_enabled                 = false
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = false
  infrastructure_encryption_enabled = false
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = false
  ssl_minimal_tls_version_enforced = "TLSEnforcementDisabled"
}


# resource "azurerm_mysql_flexible_server" "ghost-mysql" {
#   name                = "ghost-mysqlserver"
#   location            = azurerm_resource_group.ghost-blog.location
#   resource_group_name = azurerm_resource_group.ghost-blog.name
#   administrator_login          = var.mysql-login
#   administrator_password = var.mysql-password
#   sku_name   = "B_Standard_B1ms"
#   storage {
#     auto_grow_enabled = false
#     size_gb = 20
#   }
#   version    = "8.0.21"
#   backup_retention_days             = 7

# }

resource "azurerm_mysql_database" "ghost-db" {
  name                = "ghostdb"
  resource_group_name = azurerm_resource_group.ghost-blog.name
  server_name         = azurerm_mysql_server.ghost-mysql.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}


# resource "azurerm_mysql_flexible_database" "ghost-db" {
#   name                = "ghostdb"
#   resource_group_name = azurerm_resource_group.ghost-blog.name
#   server_name         = azurerm_mysql_flexible_server.ghost-mysql.name
#   charset             = "utf8"
#   collation           = "utf8_unicode_ci"
# }



resource "azapi_resource" "aca-ghost-init" {
  type = "Microsoft.App/containerApps@2022-03-01"
  name = "aca-ghost"
  parent_id = azurerm_resource_group.ghost-blog.id
  location = azurerm_resource_group.ghost-blog.location
  body = jsonencode({
    properties = {
      managedEnvironmentId = azapi_resource.acme-ghost.id
      configuration = {
        ingress = {
          external = true
          targetPort = 80
        }
      }
      template = {
        containers = [
          {
            name = "hello"
            image = "hello-world:linux"
            resources = {
              cpu = 0.5
              memory = "1.0Gi"
            }
          }         
        ]
        scale = {
          minReplicas = 1
          maxReplicas = 1
        }
      }
    }
  })
  depends_on = [
    azurerm_mysql_database.ghost-db
  ]
}

resource "azapi_resource" "aca-ghost" {
  type = "Microsoft.App/containerApps@2022-03-01"
  name = "aca-ghost"
  parent_id = azurerm_resource_group.ghost-blog.id
  location = azurerm_resource_group.ghost-blog.location
  body = jsonencode({
    properties = {
      managedEnvironmentId = azapi_resource.acme-ghost.id
      configuration = {
        ingress = {
          external = true
          targetPort = 2368
        }
      }
      template = {
        containers = [
          {
            name = "ghost-fe"
            image = "ghost:5.12.3-alpine"
            resources = {
              cpu = 1.0
              memory = "2.0Gi"
            }
            probes = [ {
              type = "Liveness"
              tcpSocket = {
                port = 2368
              }
            }
            ]
            env = [
            {
              name = "database__client"
              value = "mysql"
            },
            {
              name = "database__connection__host"
              value = azurerm_mysql_server.ghost-mysql.fqdn
            },
            {
              name = "database__connection__user"
              value = var.mysql-login
            },
            {
              name = "database__connection__password"
              value = var.mysql-password
            },
            {
              name = "database__connection__database"
              value = azurerm_mysql_database.ghost-db.name
            },
            {
              name = "url"
              # value = jsondecode(azapi_resource.aca-ghost-init.output).properties.configuration.ingress.fqdn
              value = "http://0.0.0.0"
            }
            ]
          }
        ]
        scale = {
          maxReplicas = 3
          minReplicas = 1
          rules = [ {
            name = "httpscale"
            custom = {
              type = "http"
              metadata = {
                concurrentRequests = "50"
              }
            }
          }
          ]
        }
      
      }
    }
  })
  depends_on = [
    azurerm_mysql_database.ghost-db,
    azapi_resource.aca-ghost-init
  ]
}

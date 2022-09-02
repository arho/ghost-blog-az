# resource "azapi_resource" "aca-ghost-init" {
#   type = "Microsoft.App/containerApps@2022-03-01"
#   name = "aca-ghost"
#   parent_id = azurerm_resource_group.ghost-blog.id
#   location = azurerm_resource_group.ghost-blog.location
#   body = jsonencode({
#     properties = {
#       managedEnvironmentId = azapi_resource.acme-ghost.id
#       configuration = {
#         ingress = {
#           external = true
#           targetPort = 80
#         }
#       }
#       template = {
#         containers = [
#           {
#             name = "hello"
#             image = "hello-world:linux"
#             resources = {
#               cpu = 0.5
#               memory = "1.0Gi"
#             }
#           }         
#         ]
#         scale = {
#           minReplicas = 1
#           maxReplicas = 1
#         }
#       }
#     }
#   })
#   depends_on = [
#     azurerm_mysql_database.ghost-db
#   ]
# }


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
    azurerm_mysql_database.ghost-db
  ]
}

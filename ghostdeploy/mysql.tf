# MySQL DB
# resource "azurerm_mysql_server" "ghost-mysql" {
#   name                = "ghost-mysqlserver"
#   location            = azurerm_resource_group.ghost-blog.location
#   resource_group_name = azurerm_resource_group.ghost-blog.name

#   administrator_login          = var.mysql-login
#   administrator_login_password = var.mysql-password

#   sku_name   = "B_Gen5_2"
#   storage_mb = 5120
#   version    = "8.0"

#   auto_grow_enabled                 = false
#   backup_retention_days             = 7
#   geo_redundant_backup_enabled      = false
#   infrastructure_encryption_enabled = false
#   public_network_access_enabled     = true
#   ssl_enforcement_enabled           = false
#   ssl_minimal_tls_version_enforced = "TLSEnforcementDisabled"
# }


resource "azurerm_mysql_flexible_server" "ghost-mysql" {
  name                = "ghost-mysqlserver"
  location            = azurerm_resource_group.ghost-blog.location
  resource_group_name = azurerm_resource_group.ghost-blog.name
  administrator_login          = var.mysql-login
  administrator_password = var.mysql-password
  sku_name   = "B_Standard_B1ms"
  storage {
    auto_grow_enabled = false
    size_gb = 20
  }
  version    = "8.0.21"
  backup_retention_days             = 7

}

# resource "azurerm_mysql_database" "ghost-db" {
#   name                = "ghostdb"
#   resource_group_name = azurerm_resource_group.ghost-blog.name
#   server_name         = azurerm_mysql_server.ghost-mysql.name
#   charset             = "utf8"
#   collation           = "utf8_unicode_ci"
# }


resource "azurerm_mysql_flexible_database" "ghost-db" {
  name                = "ghostdb"
  resource_group_name = azurerm_resource_group.ghost-blog.name
  server_name         = azurerm_mysql_flexible_server.ghost-mysql.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}


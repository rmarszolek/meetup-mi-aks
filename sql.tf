# --- Azure SQL Server ---
resource "azurerm_mssql_server" "main" {
  name                          = "sql-${var.environment}-${random_string.sql_suffix.result}"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  version                       = "12.0"
  administrator_login           = var.sql_admin_username
  administrator_login_password  = random_password.sql_admin_password.result
  minimum_tls_version           = "1.2"
  
  # Przypisanie tożsamości zarządzanej do serwera SQL. 
  # Jest to wymagane, aby serwer mógł autoryzować użytkowników z Entra ID.
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.sql_server.id]
  }

  primary_user_assigned_identity_id = azurerm_user_assigned_identity.sql_server.id

  # Całkowita blokada dostępu publicznego. Komunikacja tylko przez Private Endpoint.
  public_network_access_enabled = false
  
  # Konfiguracja administratora Azure Active Directory (Entra ID).
  # Maszyna VM (vm_workload) jest ustawiona jako admin, aby mogła zarządzać bazą.
  azuread_administrator {
    login_username = azurerm_user_assigned_identity.vm_workload.principal_id
    object_id      = azurerm_user_assigned_identity.vm_workload.principal_id
  }
  
  tags = var.tags
}

# Losowy sufiks dla zapewnienia unikalności nazwy serwera SQL na poziomie globalnym Azure.
resource "random_string" "sql_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Automatycznie generowane silne hasło dla konta lokalnego admina SQL.
resource "random_password" "sql_admin_password" {
  length  = 24
  special = true
}

# --- Azure SQL Database (Model Serverless) ---
resource "azurerm_mssql_database" "main" {
  name      = "sqldb-${var.environment}-main"
  server_id = azurerm_mssql_server.main.id
  
  # Konfiguracja Serverless: płacisz tylko za czas, kiedy baza jest używana.
  sku_name                    = "GP_S_Gen5_1"  # General Purpose, 1 vCore
  min_capacity                = 0.5            # Minimalna moc (pauza poniżej tej wartości)
  max_size_gb                 = 32
  auto_pause_delay_in_minutes = 60             # Automatyczne uśpienie po godzinie bezczynności.
  
  short_term_retention_policy {
    retention_days = 7
  }
  
  tags = var.tags
}

# --- PRYWATNA ŁĄCZNOŚĆ (Private Link) ---

# Prywatny punkt końcowy dla SQL Server. 
# Dzięki niemu serwer otrzymuje wewnętrzny adres IP w sieci VNet Spoke.
resource "azurerm_private_endpoint" "sql" {
  name                = "pe-sql"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.spoke_private_endpoints.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-sql"
    private_connection_resource_id = azurerm_mssql_server.main.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  # Integracja z DNS, aby nazwa serwera była rozwiązywana na prywatny adres IP.
  private_dns_zone_group {
    name                 = "pdz-group-sql"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}

# Prywatna strefa DNS wymagana przez Azure dla usługi SQL.
resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Podlinkowanie strefy DNS do sieci HUB (umożliwia maszynie VM dostęp do bazy).
resource "azurerm_private_dns_zone_virtual_network_link" "sql_hub" {
  name                  = "pdz-link-sql-hub"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = var.tags
}

# Podlinkowanie strefy DNS do sieci SPOKE (umożliwia klastrowi AKS dostęp do bazy).
resource "azurerm_private_dns_zone_virtual_network_link" "sql_spoke" {
  name                  = "pdz-link-sql-spoke"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
  registration_enabled  = false
  tags                  = var.tags
}

# --- PRZECHOWYWANIE POŚWIADCZEŃ W KEY VAULT ---

# Zapisanie hasła admina SQL w Key Vault jako sekretu.
resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = random_password.sql_admin_password.result
  key_vault_id = azurerm_key_vault.main.id
}

# Zapisanie gotowego Connection Stringa dla aplikacji.
resource "azurerm_key_vault_secret" "sql_connection_string" {
  name         = "sql-connection-string"
  value        = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Authentication=Active Directory Default;"
  key_vault_id = azurerm_key_vault.main.id
}

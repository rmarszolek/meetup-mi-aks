# Pobranie danych o bieżącej konfiguracji klienta (Tenant ID, Object ID).
data "azurerm_client_config" "current" {}

# --- Azure Key Vault ---
resource "azurerm_key_vault" "main" {
  name                       = "kv-${var.environment}-${random_string.keyvault_suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  
  # Używamy nowoczesnego modelu uprawnień RBAC zamiast starych Access Policies.
  enable_rbac_authorization       = true
  enabled_for_disk_encryption     = false
  enabled_for_deployment          = false
  enabled_for_template_deployment = false
  
  # Konfiguracja retencji dla celów testowych (soft delete na 7 dni).
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  
  # Dostęp sieciowy: zezwalamy na dostęp publiczny tylko z Twojego konkretnego adresu IP.
  public_network_access_enabled = true
  
  network_acls {
    default_action = "Deny"          # Domyślnie blokuj wszystko
    bypass         = "AzureServices" # Zezwalaj na dostęp usługom Azure (np. Backup)
    ip_rules       = [var.my_ip_address]
  }
  
  tags = var.tags
}

# Losowy sufiks dla unikalnej nazwy Key Vault.
resource "random_string" "keyvault_suffix" {
  length  = 6
  special = false
  upper   = false
}

# --- Prywatne połączenie (Private Link) dla Key Vault ---
resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-keyvault"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.spoke_private_endpoints.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-keyvault"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  # Automatyczna aktualizacja prywatnego DNS.
  private_dns_zone_group {
    name                 = "pdz-group-keyvault"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
  }
}

# Prywatna strefa DNS dedykowana dla Key Vault.
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Linkowanie strefy DNS do sieci Hub (dla maszyny zarządzającej).
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_hub" {
  name                  = "pdz-link-keyvault-hub"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = var.tags
}

# Linkowanie strefy DNS do sieci Spoke (dla klastra AKS).
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_spoke" {
  name                  = "pdz-link-keyvault-spoke"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
  registration_enabled  = false
  tags                  = var.tags
}

# Przypisanie roli administratora Key Vault dla bieżącego użytkownika (uproszczenie testów).
resource "azurerm_role_assignment" "keyvault_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Pozwala tożsamości Workload Identity na zarządzanie sekretami (tworzenie/odczyt).
resource "azurerm_role_assignment" "keyvault_secrets_officer_workload" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azurerm_user_assigned_identity.aks_workload.principal_id
}
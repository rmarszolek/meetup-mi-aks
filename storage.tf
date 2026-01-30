# --- Konto Magazynu (Storage Account) ---
# Główne miejsce przechowywania danych (w tym przypadku Azure Files).
resource "azurerm_storage_account" "main" {
  name                     = "st${var.environment}${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Replikacja lokalna (najtańsza opcja).
  account_kind             = "StorageV2"
  
  # Kontrola dostępu publicznego.
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false
  
  # Wymuszanie bezpiecznego transferu danych.
  https_traffic_only_enabled = true
  min_tls_version          = "TLS1_2"
  
  # Reguły sieciowe - domyślnie blokujemy wszystko, zezwalamy tylko na Twoje IP i usługi Azure.
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = [var.my_ip_address]
  }
  
  tags = var.tags
}

# Losowy sufiks dla unikalnej nazwy konta magazynu w skali Azure.
resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

# --- Udział plików (Azure File Share) ---
# Współdzielony folder dostępny przez protokół SMB, montowany na maszynie VM lub w Podach.
resource "azurerm_storage_share" "main" {
  name                 = "fileshare"
  storage_account_name = azurerm_storage_account.main.name
  quota                = 100 # Limit rozmiaru w GB.
  enabled_protocol     = "SMB"
  
  depends_on = [azurerm_storage_account.main]
}

# --- Prywatna łączność (Private Link) dla plików ---
# Tworzy wewnętrzny adres IP dla usługi File Share w podsieci Private Endpoints.
resource "azurerm_private_endpoint" "storage_file" {
  name                = "pe-storage-file"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.spoke_private_endpoints.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-storage-file"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["file"] # Wskazanie na usługę plików.
  }

  # Powiązanie z prywatną strefą DNS.
  private_dns_zone_group {
    name                 = "pdz-group-storage-file"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_file.id]
  }
}

# Prywatna strefa DNS wymagana dla poprawnego rozwiązywania nazw Azure Files.
resource "azurerm_private_dns_zone" "storage_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Linkowanie strefy DNS do sieci Hub (aby maszyna VM widziała udział po nazwie FQDN).
resource "azurerm_private_dns_zone_virtual_network_link" "storage_file_hub" {
  name                  = "pdz-link-storage-file-hub"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = var.tags
}

# Linkowanie strefy DNS do sieci Spoke (aby Pod w AKS mógł montować udział).
resource "azurerm_private_dns_zone_virtual_network_link" "storage_file_spoke" {
  name                  = "pdz-link-storage-file-spoke"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_file.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
  registration_enabled  = false
  tags                  = var.tags
}
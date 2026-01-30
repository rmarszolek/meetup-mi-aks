# --- Sieć Wirtualna SPOKE ---
# Środowisko robocze dla klastra AKS i usług PaaS.
resource "azurerm_virtual_network" "spoke" {
  name                = var.spoke_vnet_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.spoke_vnet_address_space
  tags                = var.tags
}

# Podsieć dedykowana dla warstwy sterowania AKS (System Pool).
resource "azurerm_subnet" "spoke_aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.spoke_aks_subnet_address_prefix]
}

# Podsieć dla węzłów roboczych AKS (Worker Nodes) oraz Podów.
resource "azurerm_subnet" "spoke_nodes" {
  name                 = "snet-aks-nodes"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.spoke_nodes_subnet_address_prefix]
}

# Izolowana podsieć wyłącznie dla prywatnych punktów końcowych (SQL, Key Vault, Storage).
resource "azurerm_subnet" "spoke_private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.spoke_private_endpoints_subnet_address_prefix]
}

# --- Grupy Bezpieczeństwa Sieci (NSG) dla Spoke ---

# NSG dla podsieci sterującej AKS.
resource "azurerm_network_security_group" "spoke_aks" {
  name                = "nsg-spoke-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  security_rule {
    name                       = "AllowVnetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    source_port_range          = "*"
    destination_port_range     = "*"
  }
}

# NSG dla podsieci węzłów roboczych.
resource "azurerm_network_security_group" "spoke_nodes" {
  name                = "nsg-spoke-nodes"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  security_rule {
    name                       = "AllowVnetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    source_port_range          = "*"
    destination_port_range     = "*"
  }
}

# NSG dla prywatnych punktów końcowych - najbardziej restrykcyjne reguły.
resource "azurerm_network_security_group" "spoke_private_endpoints" {
  name                = "nsg-spoke-private-endpoints"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  # Zezwalamy na HTTPS z Twojego adresu IP (zarządzanie portalem/cli).
  security_rule {
    name                       = "AllowHttpsFromMyIP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.my_ip_address
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHttpFromMyIP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.my_ip_address
    destination_address_prefix = "*"
  }

  # Zezwalamy maszynie zarządzającej w Hub na dostęp HTTPS/HTTP.
  security_rule {
    name                       = "AllowHttpsFromHubVM"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = azurerm_network_interface.hub_vm.private_ip_address
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHttpFromHubVM"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = azurerm_network_interface.hub_vm.private_ip_address
    destination_address_prefix = "*"
  }

  # SMB (port 445) tylko z maszyny Hub - dla Azure Files.
  security_rule {
    name                       = "AllowSmbFromHubVM"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "445"
    source_address_prefix      = azurerm_network_interface.hub_vm.private_ip_address
    destination_address_prefix = "*"
  }

  # Dostęp SQL (1433) z maszyny Hub.
  security_rule {
    name                       = "AllowSqlFromHubVM"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = azurerm_network_interface.hub_vm.private_ip_address
    destination_address_prefix = "*"
  }

  # Dostęp SQL (1433) bezpośrednio z podsieci sterującej AKS.
  security_rule {
    name                       = "AllowSqlFromAKS"
    priority                   = 160
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = var.spoke_aks_subnet_address_prefix
    destination_address_prefix = "*"
  }

  # Dostęp SQL (1433) z podsieci węzłów (dla Twoich Podów).
  security_rule {
    name                       = "AllowSqlFromAKSNodes"
    priority                   = 170
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = var.spoke_nodes_subnet_address_prefix
    destination_address_prefix = "*"
  }

  # Blokada całego pozostałego ruchu przychodzącego do podsieci PE.
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# --- Powiązania NSG z podsieciami ---

resource "azurerm_subnet_network_security_group_association" "spoke_aks" {
  subnet_id                 = azurerm_subnet.spoke_aks.id
  network_security_group_id = azurerm_network_security_group.spoke_aks.id
}

resource "azurerm_subnet_network_security_group_association" "spoke_nodes" {
  subnet_id                 = azurerm_subnet.spoke_nodes.id
  network_security_group_id = azurerm_network_security_group.spoke_nodes.id
}

resource "azurerm_subnet_network_security_group_association" "spoke_private_endpoints" {
  subnet_id                 = azurerm_subnet.spoke_private_endpoints.id
  network_security_group_id = azurerm_network_security_group.spoke_private_endpoints.id
}
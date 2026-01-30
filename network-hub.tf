# --- Sieć Wirtualna HUB ---
# Centralny punkt zarządzania infrastrukturą.
resource "azurerm_virtual_network" "hub" {
  name                = var.hub_vnet_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.hub_vnet_address_space
  tags                = var.tags
}

# Podsieć dla maszyny zarządzającej (Jumpbox).
resource "azurerm_subnet" "hub_vm" {
  name                 = "snet-vm"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub_subnet_address_prefix]
}

# --- Grupa Bezpieczeństwa Sieci (NSG) dla Hub VM ---
resource "azurerm_network_security_group" "hub_vm" {
  name                = "nsg-hub-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  # Zezwalamy na dostęp SSH wyłącznie z Twojego publicznego adresu IP.
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.my_ip_address
    destination_address_prefix = azurerm_network_interface.hub_vm.private_ip_address
  }
}

# Powiązanie NSG z podsiecią maszyny VM.
resource "azurerm_subnet_network_security_group_association" "hub_vm" {
  subnet_id                 = azurerm_subnet.hub_vm.id
  network_security_group_id = azurerm_network_security_group.hub_vm.id
}

# Publiczny adres IP dla maszyny VM (umożliwia połączenie z internetu).
resource "azurerm_public_ip" "hub_vm" {
  name                = "pip-hub-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Interfejs sieciowy dla maszyny zarządzającej.
resource "azurerm_network_interface" "hub_vm" {
  name                = "nic-hub-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.hub_vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.hub_vm.id
  }
}

# --- Maszyna Wirtualna (Ubuntu) w sieci HUB ---
# Służy jako bezpieczny punkt dostępu do zasobów prywatnych w sieci Spoke.
resource "azurerm_linux_virtual_machine" "hub" {
  name                = "vm-hub-ubuntu"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.vm_size
  admin_username      = var.vm_admin_username
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.hub_vm.id,
  ]

  # Autoryzacja wyłącznie za pomocą klucza SSH.
  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    name                 = "osdisk-hub-vm"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"  # Generacja 2 dla nowoczesnych funkcji security.
    version   = "22.04.202204200"
  }

  disable_password_authentication = true
}
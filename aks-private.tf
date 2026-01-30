# --- 1. PRYWATNA STREFA DNS DLA AKS ---
# Wymagana dla klastrów prywatnych, aby nazwa API Servera była rozwiązywalna wewnątrz sieci VNet.
resource "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.main.name
}

# --- 2. PODLINKOWANIE DNS DO SIECI SPOKE ---
# Umożliwia węzłom (Nodes) w sieci Spoke kontakt z API Serverem.
resource "azurerm_private_dns_zone_virtual_network_link" "spoke" {
  name                  = "link-spoke"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
}

# --- 3. PODLINKOWANIE DNS DO SIECI HUB ---
# Umożliwia maszynie zarządzającej (Jumpbox) kontakt z API Serverem AKS.
resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  name                  = "link-hub"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = azurerm_virtual_network.hub.id
}

# --- 4. GŁÓWNA KONFIGURACJA KLASTRA AKS ---
resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.environment}-cluster"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "aks-${var.environment}"

  # KONFIGURACJA KLASTRA PRYWATNEGO:
  # API Server nie jest dostępny z internetu.
  private_cluster_enabled     = true
  private_dns_zone_id         = azurerm_private_dns_zone.aks.id
  
  kubernetes_version        = var.aks_kubernetes_version
  automatic_upgrade_channel = "patch"

  # Tożsamość klastra (Control Plane).
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_cluster.id]
  }

  # Tożsamość Kubeleta - używana bezpośrednio przez węzły.
  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.aks_kubelet.client_id
    object_id                 = azurerm_user_assigned_identity.aks_kubelet.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.aks_kubelet.id
  }

  # Domyślna pula systemowa (System Node Pool).
  default_node_pool {
    name                = "system"
    node_count          = 1
    vm_size             = var.aks_system_node_size
    vnet_subnet_id      = azurerm_subnet.spoke_aks.id
    auto_scaling_enabled = true
    min_count           = 1
    max_count           = 3
  }

  # Konfiguracja sieciowa klastra.
  network_profile {
    network_plugin    = "azure"   # Azure CNI (każdy Pod ma IP z VNet)
    network_policy    = "azure"   # Azure Network Policy Manager
    load_balancer_sku = "standard"
  }

  # --- KLUCZOWE FUNKCJE DLA WORKLOAD IDENTITY ---
  workload_identity_enabled = true # Włącza mechanizm Workload Identity.
  oidc_issuer_enabled       = true # Włącza wystawcę tokenów OIDC (wymagane dla federacji).

  # Integracja z Azure RBAC dla Kubernetesa (opcjonalnie).
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.admin_ids != null ? [1] : []
    content {
      azure_rbac_enabled     = true
      admin_group_object_ids = var.admin_ids
    }
  }

  depends_on = [
    azurerm_role_assignment.aks_cluster_network,
    azurerm_private_dns_zone_virtual_network_link.hub,
    azurerm_private_dns_zone_virtual_network_link.spoke
  ]
}

# --- DODATKOWA PULA WĘZŁÓW (Worker Node Pool) ---
resource "azurerm_kubernetes_cluster_node_pool" "worker" {
  name                  = "worker"
  temporary_name_for_rotation = "workertemp"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.aks_worker_node_size
  node_count            = 1
  min_count             = 1
  max_count             = 3
  auto_scaling_enabled   = true
  os_disk_size_gb       = 30
  os_disk_type          = "Managed"
  
  # Umieszczenie węzłów roboczych w dedykowanej podsieci.
  vnet_subnet_id = azurerm_subnet.spoke_nodes.id
  
  node_labels = {
    "nodepool-type" = "worker"
    "environment"   = var.environment
    "workload"      = "application"
  }
  
  tags = merge(
    var.tags,
    {
      "nodepool" = "worker"
    }
  )
}

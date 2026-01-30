# --- RBAC DLA AKS: Uprawnienia administracyjne dla użytkownika/grupy ---
resource "azurerm_role_assignment" "aks_rbac_admin" {
  count                = var.admin_ids != null && length(var.admin_ids) > 0 ? 1 : 0
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = var.admin_ids[0]
}

# --- TOŻSAMOŚCI ZARZĄDZANE (User Assigned Managed Identities) ---

# Tożsamość sterująca klastrem AKS (Control Plane). 
# Używana do zarządzania zasobami takimi jak Load Balancery czy Dyski w Azure.
resource "azurerm_user_assigned_identity" "aks_cluster" {
  name                = "id-aks-cluster"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Tożsamość używana przez Kubelet na węzłach (Nodes). 
# Odpowiada m.in. za pobieranie obrazów z ACR.
resource "azurerm_user_assigned_identity" "aks_kubelet" {
  name                = "id-aks-kubelet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Główna tożsamość dla Workload Identity. 
# To z tą tożsamością będą "rozmawiać" Pody w Kubernetesie, aby dostać się do Key Vault czy Storage.
resource "azurerm_user_assigned_identity" "aks_workload" {
  name                = "id-aks-workload"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Tożsamość dla maszyny wirtualnej (Jumpbox/Admin VM). 
# Pozwala na bezpieczne zarządzanie infrastrukturą bez haseł.
resource "azurerm_user_assigned_identity" "vm_workload" {
  name                = "id-vm-workload"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Tożsamość dedykowana dla serwera SQL. 
# Dzięki niej silnik bazy danych może "czytać" katalog Entra ID (użytkowników/grupy).
resource "azurerm_user_assigned_identity" "sql_server" {
  name                = "sql-user-mi"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# --- PRZYPISANIA RÓL (RBAC) ---

# Pozwala klastrowi AKS zarządzać siecią w VNet Spoke (np. tworzyć prywatne IP dla usług).
resource "azurerm_role_assignment" "aks_cluster_network" {
  scope                = azurerm_virtual_network.spoke.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_cluster.principal_id
}

# Niezbędne, aby tożsamość klastra mogła zarządzać tożsamością Kubeleta.
resource "azurerm_role_assignment" "aks_cluster_kubelet_operator" {
  scope                = azurerm_user_assigned_identity.aks_kubelet.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.aks_cluster.principal_id
}

# Pobranie grupy zasobów węzłów (MC_...), gdzie AKS trzyma swoje zasoby techniczne.
data "azurerm_resource_group" "node_rg" {
  name = azurerm_kubernetes_cluster.main.node_resource_group
  depends_on = [azurerm_kubernetes_cluster.main]
}

# Pozwala klastrowi operować na tożsamościach wewnątrz grupy zasobów węzłów.
resource "azurerm_role_assignment" "aks_cluster_kubelet_operator_mc" {
  scope                = data.azurerm_resource_group.node_rg.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.aks_cluster.principal_id
  depends_on = [azurerm_kubernetes_cluster.main]
}

# Pozwala klastrowi AKS na wpisy w prywatnej strefie DNS (wymagane dla Private Cluster).
resource "azurerm_role_assignment" "aks_dns" {
  scope                = azurerm_private_dns_zone.aks.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_cluster.principal_id
}

# --- UPRAWNIENIA DO KEY VAULT (RBAC) ---

# Pozwala Podom (Workload Identity) na czytanie sekretów.
resource "azurerm_role_assignment" "workload_keyvault_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.aks_workload.principal_id
}

# Pozwala maszynie VM na czytanie sekretów (np. hasła do SQL).
resource "azurerm_role_assignment" "vm_workload_keyvault_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.vm_workload.principal_id
}

# --- UPRAWNIENIA DO STORAGE ACCOUNT (RBAC) ---

# Zarządzanie kontem magazynu (Control Plane) - np. tworzenie udziałów.
resource "azurerm_role_assignment" "workload_storage_mgmt" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_workload.principal_id
}

# Rola Reader jest czasem wymagana do listowania kluczy/właściwości konta.
resource "azurerm_role_assignment" "workload_storage_mgmt_reader" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.aks_workload.principal_id
}

resource "azurerm_role_assignment" "workload_storage_mgmt_vm" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.vm_workload.principal_id
}

# Uprawnienia do danych (Data Plane) - odczyt/zapis plików wewnątrz Azure Files.
resource "azurerm_role_assignment" "workload_storage_data" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_workload.principal_id
}

resource "azurerm_role_assignment" "workload_storage_data_vm" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = azurerm_user_assigned_identity.vm_workload.principal_id
}

# Nadaje maszynie VM rolę admina na klastrze AKS (przez Azure RBAC).
resource "azurerm_role_assignment" "workload_aks_vm" {
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = azurerm_user_assigned_identity.vm_workload.principal_id
}

# --- INTEGRACJA Z ENTRA ID (Directory Readers) ---

# Aktywacja roli Directory Readers w tenancie. 
# Wymagane, aby tożsamości mogły "widzieć" innych użytkowników w katalogu Entra ID.
resource "azuread_directory_role" "directory_readers" {
  display_name = "Directory Readers"
}

# Przypisanie maszyny VM do roli Directory Readers (aby mogła dodawać userów do SQL).
resource "azuread_directory_role_member" "vm_workload_directory_reader" {
  role_object_id   = azuread_directory_role.directory_readers.object_id
  member_object_id = azurerm_user_assigned_identity.vm_workload.principal_id
}

# Przypisanie serwera SQL do roli Directory Readers (aby silnik bazy mógł weryfikować userów AD).
resource "azuread_directory_role_member" "sql_server_directory_reader" {
  role_object_id   = azuread_directory_role.directory_readers.object_id
  member_object_id = azurerm_user_assigned_identity.sql_server.principal_id
}

# --- FEDERACJA TOŻSAMOŚCI (Workload Identity) ---

# Mechanizm łączący tożsamość Azure z kontem serwisowym w Kubernetes (Service Account).
# Dzięki temu Pod może "stać się" tożsamością Azure bez używania haseł/kluczy.
resource "azurerm_federated_identity_credential" "workload" {
  name                       = "fic-workload-identity"
  resource_group_name        = azurerm_resource_group.main.name
  parent_id                  = azurerm_user_assigned_identity.aks_workload.id
  
  # URL wystawcy OIDC pobrany z klastra AKS.
  issuer                     = azurerm_kubernetes_cluster.main.oidc_issuer_url
  
  # Definicja który konkretnie ServiceAccount w K8s może używać tej tożsamości.
  # Format: system:serviceaccount:<namespace>:<serviceaccount_name>
  subject                    = "system:serviceaccount:work:workload"
  
  # Grupa docelowa dla tokenu.
  audience                  = ["api://AzureADTokenExchange"]

  depends_on = [azurerm_kubernetes_cluster.main]
}
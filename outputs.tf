output "aks_cluster_fqdn" {
  value = azurerm_kubernetes_cluster.main.fqdn
}

output "aks_cluster_id" {
  value = azurerm_kubernetes_cluster.main.id
}

output "aks_cluster_identity_client_id" {
  value = azurerm_user_assigned_identity.aks_cluster.client_id
}

output "aks_cluster_identity_id" {
  value = azurerm_user_assigned_identity.aks_cluster.id
}

output "aks_cluster_identity_principal_id" {
  value = azurerm_user_assigned_identity.aks_cluster.principal_id
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_portal_fqdn" {
  value = azurerm_kubernetes_cluster.main.portal_fqdn
}

output "aks_connect_command" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

output "aks_get_credentials_command" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

output "aks_kubelet_identity_client_id" {
  value = azurerm_user_assigned_identity.aks_kubelet.client_id
}

output "aks_kubelet_identity_id" {
  value = azurerm_user_assigned_identity.aks_kubelet.id
}

output "aks_node_resource_group" {
  value = azurerm_kubernetes_cluster.main.node_resource_group
}

output "aks_oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "aks_private_fqdn" {
  value = azurerm_kubernetes_cluster.main.private_fqdn
}

output "aks_workload_identity_client_id" {
  value = azurerm_user_assigned_identity.aks_workload.client_id
}

output "aks_workload_identity_id" {
  value = azurerm_user_assigned_identity.aks_workload.id
}

output "aks_workload_identity_principal_id" {
  value = azurerm_user_assigned_identity.aks_workload.principal_id
}

output "hub_subnet_id" {
  value = azurerm_subnet.hub_vm.id
}

output "hub_vnet_id" {
  value = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  value = azurerm_virtual_network.hub.name
}

output "keyvault_id" {
  value = azurerm_key_vault.main.id
}

output "keyvault_name" {
  value = azurerm_key_vault.main.name
}

output "keyvault_private_endpoint_ip" {
  value = azurerm_private_endpoint.keyvault.private_service_connection[0].private_ip_address
}

output "keyvault_uri" {
  value = azurerm_key_vault.main.vault_uri
}

output "kubelogin_convert_command" {
  value = "kubelogin convert-kubeconfig -l azurecli"
}

output "private_dns_zone_keyvault" {
  value = azurerm_private_dns_zone.keyvault.name
}

output "private_dns_zone_sql" {
  value = azurerm_private_dns_zone.sql.name
}

output "private_dns_zone_storage_file" {
  value = azurerm_private_dns_zone.storage_file.name
}

output "resource_group_location" {
  value = azurerm_resource_group.main.location
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "spoke_aks_subnet_id" {
  value = azurerm_subnet.spoke_aks.id
}

output "spoke_nodes_subnet_id" {
  value = azurerm_subnet.spoke_nodes.id
}

output "spoke_private_endpoints_subnet_id" {
  value = azurerm_subnet.spoke_private_endpoints.id
}

output "spoke_vnet_id" {
  value = azurerm_virtual_network.spoke.id
}

output "spoke_vnet_name" {
  value = azurerm_virtual_network.spoke.name
}

output "sql_connection_string_keyvault_secret" {
  value = azurerm_key_vault_secret.sql_connection_string.name
}

output "sql_database_name" {
  value = azurerm_mssql_database.main.name
}

output "sql_private_endpoint_ip" {
  value = azurerm_private_endpoint.sql.private_service_connection[0].private_ip_address
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "sql_server_identity_client_id" {
  value = azurerm_user_assigned_identity.sql_server.client_id
}

output "sql_server_name" {
  value = azurerm_mssql_server.main.name
}

output "storage_account_id" {
  value = azurerm_storage_account.main.id
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}

output "storage_file_mount_command" {
  value = "sudo mount -t cifs //${azurerm_storage_account.main.name}.file.core.windows.net/${azurerm_storage_share.main.name} /mnt/fileshare -o vers=3.0,username=${azurerm_storage_account.main.name},password=<STORAGE_KEY>,dir_mode=0777,file_mode=0777,serverino"
}

output "storage_file_share_name" {
  value = azurerm_storage_share.main.name
}

output "storage_private_endpoint_ip" {
  value = azurerm_private_endpoint.storage_file.private_service_connection[0].private_ip_address
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.hub.name
}

output "vm_private_ip" {
  value = azurerm_linux_virtual_machine.hub.private_ip_address
}

output "vm_public_ip" {
  value = azurerm_public_ip.hub_vm.ip_address
}

output "vm_ssh_command" {
  value = "ssh ${azurerm_linux_virtual_machine.hub.admin_username}@${azurerm_public_ip.hub_vm.ip_address}"
}

output "vm_workload_identity_client_id" {
  value = azurerm_user_assigned_identity.vm_workload.client_id
}

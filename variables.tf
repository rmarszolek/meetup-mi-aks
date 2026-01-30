variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}


variable "admin_ids"  {
  description = "Azure AD Admin Group Object IDs for AKS"
  type        = list(string)
  default     = []
}
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-meetup-aks"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# Hub VNet variables
variable "hub_vnet_name" {
  description = "Name of the Hub VNet"
  type        = string
  default     = "vnet-hub"
}

variable "hub_vnet_address_space" {
  description = "Address space for Hub VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "hub_subnet_address_prefix" {
  description = "Address prefix for Hub subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# Spoke VNet variables
variable "spoke_vnet_name" {
  description = "Name of the Spoke VNet"
  type        = string
  default     = "vnet-spoke"
}

variable "spoke_vnet_address_space" {
  description = "Address space for Spoke VNet"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "spoke_aks_subnet_address_prefix" {
  description = "Address prefix for AKS subnet in Spoke"
  type        = string
  default     = "10.1.0.0/20"
}

variable "spoke_nodes_subnet_address_prefix" {
  description = "Address prefix for AKS nodes subnet in Spoke"
  type        = string
  default     = "10.1.16.0/20"
}

variable "spoke_private_endpoints_subnet_address_prefix" {
  description = "Address prefix for Private Endpoints subnet in Spoke"
  type        = string
  default     = "10.1.32.0/24"
}

# VM variables
variable "vm_admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "vm_size" {
  description = "Size of the VM"
  type        = string
  default     = "Standard_B2ms"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key for VM access"
  type        = string
  default     = "C:\\Users\\rmars\\.ssh\\id_rsa.pub" # dla linux "~/.ssh/id_rsa.pub"
}

variable "my_ip_address" {
  description = "Your public IP address for SSH access"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "meetup-aks"
    ManagedBy   = "Terraform"
  }
}

# AKS variables
variable "aks_kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.33"
}

variable "aks_system_node_size" {
  description = "VM size for system node pool"
  type        = string
  default     = "Standard_B2s"
}

variable "aks_worker_node_size" {
  description = "VM size for worker node pool"
  type        = string
  default     = "Standard_A4_v2"
}

variable "aks_system_node_count" {
  description = "Initial number of nodes in system pool"
  type        = number
  default     = 1
}

variable "aks_worker_node_count" {
  description = "Initial number of nodes in worker pool"
  type        = number
  default     = 1
}

# SQL variables
variable "sql_admin_username" {
  description = "SQL Server administrator username"
  type        = string
  default     = "sqladmin"
}

variable "aks_cluster_name" {
  type        = string
  description = "Nazwa klastra AKS"
}

variable "location" {
  type        = string
  description = "Lokalizacja zasobów w Azure"
  default     = "West Europe"
}

variable "resource_group_name" {
  type        = string
  description = "RG, w którym tworzysz AKS (RG musi już istnieć)"
}

variable "vnet_subnet_id" {
  type        = string
  description = "ID subnetu dla AKS (Azure CNI). Subnet/VNet tworzone poza modułem."
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix dla AKS (opcjonalnie)"
  default     = null
}

variable "kubernetes_version" {
  type        = string
  description = "Wersja Kubernetes (opcjonalnie, null = domyślna w regionie)"
  default     = null
}

variable "private_cluster_enabled" {
  type        = bool
  description = "Czy AKS ma być private cluster"
  default     = false
}

# Jeśli null -> blok nie jest tworzony (unikasz problemów z pustą listą)
variable "api_server_authorized_ip_ranges" {
  type        = list(string)
  description = "Lista publicznych CIDR/IP dopuszczonych do API server (null = brak ograniczenia)"
  default     = null
}

variable "tenant_id" {
  type        = string
  description = "Tenant ID dla AAD RBAC (opcjonalnie)"
  default     = null
}

variable "aad_admin_group_object_ids" {
  type        = list(string)
  description = "Object IDs grup Entra ID będących adminami klastra (opcjonalnie)"
  default     = null
}

variable "local_account_disabled" {
  type        = bool
  description = "Wyłącza local accounts na AKS (zalecane gdy masz AAD RBAC)"
  default     = true
}

variable "node_count" {
  type        = number
  default     = 1
  description = "Liczba węzłów w puli systemowej"
}

variable "node_vm_size" {
  type        = string
  default     = "Standard_DS2_v2"
  description = "Rozmiar VM dla puli systemowej"
}

variable "system_node_pool_name" {
  type        = string
  default     = "system"
  description = "Nazwa systemowego nodepool"
}

variable "system_max_pods" {
  type        = number
  default     = 110
  description = "max_pods dla systemowego nodepool"
}

variable "network_policy" {
  type        = string
  default     = "azure"
  description = "Network policy (np. azure/calico w zależności od konfiguracji)"
}

variable "dns_service_ip" {
  type        = string
  default     = "10.1.0.10"
  description = "DNS service IP (musi być w service_cidr)"
}

variable "service_cidr" {
  type        = string
  default     = "10.1.0.0/16"
  description = "Service CIDR dla AKS"
}

# Monitoring / Log Analytics
variable "enable_oms_agent" {
  type        = bool
  default     = true
  description = "Czy włączyć OMS agent / Log Analytics"
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "Jeśli podasz, moduł nie tworzy LAW. Jeśli null i enable_oms_agent=true, stworzy LAW."
}

variable "log_analytics_sku" {
  type        = string
  default     = "PerGB2018"
  description = "SKU Log Analytics"
}

variable "log_analytics_retention_days" {
  type        = number
  default     = 30
  description = "Retencja LAW w dniach"
}

# Tags
variable "tags" {
  type        = map(string)
  default     = {}
  description = "Dodatkowe tagi"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Nazwa środowiska do tagów"
}

# ========== Dodatkowy node pool ==========
variable "enable_additional_pool" {
  type        = bool
  default     = false
  description = "Czy utworzyć dodatkowy user node pool"
}

variable "additional_pool_mode" {
  type        = string
  default     = "Standard"
  description = "Spot lub Standard"
  validation {
    condition     = contains(["Spot", "Standard"], var.additional_pool_mode)
    error_message = "additional_pool_mode musi być 'Spot' lub 'Standard'."
  }
}

variable "additional_pool_name" {
  type        = string
  default     = "extra"
  description = "Nazwa dodatkowej puli"
}

variable "additional_pool_vm_size" {
  type        = string
  default     = "Standard_DS2_v2"
  description = "VM size dodatkowej puli"
}

variable "additional_pool_node_count" {
  type        = number
  default     = 1
  description = "Początkowa liczba węzłów (i/lub aktualna przy autoscalingu)"
}

variable "additional_pool_enable_auto_scaling" {
  type        = bool
  default     = true
  description = "Czy autoscaling w dodatkowej puli"
}

variable "additional_pool_min_count" {
  type        = number
  default     = 1
  description = "Min nodes (autoscaling)"
}

variable "additional_pool_max_count" {
  type        = number
  default     = 5
  description = "Max nodes (autoscaling)"
}

variable "additional_pool_max_pods" {
  type        = number
  default     = 110
  description = "max_pods w dodatkowej puli"
}

variable "additional_pool_spot_max_price" {
  type        = number
  default     = -1
  description = "Spot max price (-1 = on-demand price)"
}

###############################
# Core AKS
###############################

variable "aks_cluster_name" {
  type        = string
  description = "Nazwa klastra AKS"
}

variable "location" {
  type        = string
  description = "Lokalizacja zasobów w Azure"
  default     = "westeurope"
}

variable "resource_group_name" {
  type        = string
  description = "Resource Group, w którym tworzony jest AKS"
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
  description = "Wersja Kubernetes (null = domyślna dla regionu)"
  default     = null
}

variable "private_cluster_enabled" {
  type        = bool
  description = "Czy AKS ma być private cluster"
  default     = false
}

###############################
# API Server Access
###############################

variable "api_server_authorized_ip_ranges" {
  type        = list(string)
  description = "Lista CIDR/IP dopuszczonych do API Server (null = brak ograniczeń)"
  default     = null
}

###############################
# Azure AD / RBAC
###############################

variable "tenant_id" {
  type        = string
  description = "Tenant ID (wymagany gdy używasz AAD RBAC)"
  default     = null
}

variable "aad_admin_group_object_ids" {
  type        = list(string)
  description = "Object IDs grup Entra ID będących adminami klastra"
  default     = null
}

variable "local_account_disabled" {
  type        = bool
  description = "Wyłącza local accounts (zalecane przy AAD RBAC)"
  default     = false
}

###############################
# System Node Pool
###############################

variable "system_node_pool_name" {
  type        = string
  description = "Nazwa systemowego nodepool"
  default     = "system"
}

variable "node_count" {
  type        = number
  description = "Liczba węzłów w systemowym nodepool"
  default     = 1
}

variable "node_vm_size" {
  type        = string
  description = "VM size systemowego nodepool"
  default     = "Standard_B4ms"
}

variable "system_max_pods" {
  type        = number
  description = "max_pods dla systemowego nodepool"
  default     = 110
}

###############################
# Networking
###############################

variable "network_policy" {
  type        = string
  description = "Network policy (azure)"
  default     = "azure"
}

variable "dns_service_ip" {
  type        = string
  description = "DNS Service IP (musi być w service_cidr)"
  default     = "10.1.0.10"
}

variable "service_cidr" {
  type        = string
  description = "Service CIDR dla AKS"
  default     = "10.1.0.0/16"
}

###############################
# Additional User Node Pool
###############################

variable "enable_additional_pool" {
  type        = bool
  description = "Czy utworzyć dodatkowy user node pool"
  default     = false
}

variable "additional_pool_name" {
  type        = string
  description = "Nazwa dodatkowej puli"
  default     = "extra"
}

variable "additional_pool_vm_size" {
  type        = string
  description = "VM size dodatkowej puli"
  default     = "Standard_B4ms"
}

variable "additional_pool_node_count" {
  type        = number
  description = "Node count (lub startowa przy autoscaling)"
  default     = 1
}

variable "additional_pool_enable_auto_scaling" {
  type        = bool
  description = "Czy autoscaling w dodatkowej puli"
  default     = true
}

variable "additional_pool_min_count" {
  type        = number
  description = "Min nodes (autoscaling)"
  default     = 1
}

variable "additional_pool_max_count" {
  type        = number
  description = "Max nodes (autoscaling)"
  default     = 5
}

variable "additional_pool_max_pods" {
  type        = number
  description = "max_pods w dodatkowej puli"
  default     = 110
}

variable "additional_pool_mode" {
  type        = string
  description = "Tryb puli: Spot lub Standard"
  default     = "Standard"

  validation {
    condition     = contains(["Spot", "Standard"], var.additional_pool_mode)
    error_message = "additional_pool_mode musi być 'Spot' lub 'Standard'."
  }
}

variable "additional_pool_spot_max_price" {
  type        = number
  description = "Spot max price (-1 = cena on-demand)"
  default     = -1
}

###############################
# Managed Observability
###############################

variable "enable_managed_prometheus" {
  type        = bool
  description = "Włącza Azure Monitor Managed Prometheus"
  default     = true
}

variable "enable_oms_agent" {
  type        = bool
  description = "Enable Container Insights / OMS agent"
  default     = true
}

###############################
# Tags
###############################

variable "tags" {
  type        = map(string)
  description = "Dodatkowe tagi"
  default     = {}
}

variable "environment" {
  type        = string
  description = "Środowisko (do tagów)"
  default     = "dev"
}

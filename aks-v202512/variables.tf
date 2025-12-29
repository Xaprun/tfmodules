variable "name" {
  type        = string
  description = "AKS cluster name"
}

variable "location" {
  type        = string
}

variable "resource_group_name" {
  type        = string
}

variable "vnet_subnet_id" {
  type        = string
}

variable "dns_prefix" {
  type    = string
  default = null
}

variable "kubernetes_version" {
  type    = string
  default = null
}

variable "private_cluster_enabled" {
  type    = bool
  default = false
}

variable "api_server_authorized_ip_ranges" {
  type    = list(string)
  default = null
}

variable "tenant_id" {
  type    = string
  default = null
}

variable "aad_admin_group_object_ids" {
  type    = list(string)
  default = null
}

variable "local_account_disabled" {
  type    = bool
  default = false
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "network_policy" {
  type    = string
  default = "azure"
}

variable "dns_service_ip" {
  type    = string
  default = "10.1.0.10"
}

variable "service_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "system_node_pool" {
  type = object({
    name       = string
    vm_size    = string
    node_count = number
    max_pods   = number
  })
}

variable "user_node_pool" {
  type = object({
    name                  = string
    vm_size               = string
    node_count            = number
    min_count             = number
    max_count             = number
    max_pods              = number
    enable_auto_scaling   = bool
    spot                  = bool
    spot_max_price        = number
  })
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "environment" {
  type    = string
  default = "dev"
}

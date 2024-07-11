variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location of the resource group"
  type        = string
  default     = "eastus"
}

variable "aks_cluster_name" {
  description = "The name of the AKS cluster"
  type        = string
}

variable "node_count" {
  description = "The number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "node_vm_size" {
  description = "The size of the VM in the node pool"
  type        = string
  default     = "Standard_DS2_v2"
}

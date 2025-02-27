variable "aks_cluster_authorized_ip"
  type        = array
  description = "Adresy IP, z których można komunikować się z klastrem AKS"
  # default     = ["10.0.0.0/16", "192.168.0.0/16"]

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
  description = "Nazwa grupy zasobów w Azure, w której zostanie utworzony klaster"
}

variable "node_count" {
  type        = number
  default     = 1
  description = "Liczba węzłów w puli default (System)"
}

variable "node_vm_size" {
  type        = string
  default     = "Standard_DS2_v2"
  description = "Rozmiar maszyny w puli default"
}

# ========== Nowe zmienne dla dodatkowej puli ==========

variable "enable_additional_pool" {
  type        = bool
  default     = false
  description = "Czy utworzyć dodatkową pulę węzłów (domyślnie false)?"
}

variable "additional_pool_mode" {
  type        = string
  default     = "Standard"
  description = "Typ dodatkowej puli: 'Spot' lub 'Standard'"
  validation {
    condition     = contains(["Spot", "Standard"], var.additional_pool_mode)
    error_message = "Wartość additional_pool_mode musi być 'Spot' lub 'Standard'."
  }
}

variable "additional_pool_name" {
  type        = string
  default     = "extra"
  description = "Nazwa dodatkowej puli węzłów"
}

variable "additional_pool_vm_size" {
  type        = string
  default     = "Standard_DS2_v2"
  description = "Rozmiar maszyny w dodatkowej puli"
}

variable "additional_pool_node_count" {
  type        = number
  default     = 2
  description = "Liczba węzłów w dodatkowej puli"
}

variable "additional_pool_min_count" {
  type        = number
  default     = 1
  description = "Minimalna liczba węzłów (auto-scaling) w dodatkowej puli"
}

variable "additional_pool_max_count" {
  type        = number
  default     = 5
  description = "Maksymalna liczba węzłów (auto-scaling) w dodatkowej puli"
}

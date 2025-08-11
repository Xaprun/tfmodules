# variables.tf
variable "subnet_id" {
  description = "ID of the subnet to attach NICs to"
  type        = string
}

variable "environment" {
  type = string
  default = "prod"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "resource_group_location" {
  description = "The location of the resource group"
  type        = string
}

# variable "vm_config" {
#   type = map(object({
#     private_ip       = string
#     public_ip_name   = string
#    machine_type     = string
#    machine_description = string
#  }))
# }

variable "network_name" {
  description = "The name of the network"
  type        = string
}

variable "firewall_rules" {
  description = "Map of firewall rules configuration"
  type = map(object({
    protocol         = string
    ports            = list(string)
    priority         = number
    description      = string
    source_address_prefix = list(string)
  }))
}

#######################
### ADDED VARIABLES ###
#######################
variable "public_subnet_name" {
  description = "The name of public subnet used in data"
  type        = string
  default     = "subnet-public"
}

variable "admin_username" {
  type    = string
  default = "admin"
}

variable "admin_ssh_key_path" {
  description = "Path to the public SSH key file"
  type        = string
  default     = "ssh/admin_key.pub"
}

variable "image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Debian"
    offer     = "debian-11"
    sku       = "11"
    version   = "latest"
  }
}

variable "custom_data_file" {
  description = "Path to cloud-init script or custom data file"
  type     = string
  default  = null
  nullable = true
}

# variables.tf
variable "enable_public_ip" {
  type    = bool
  default = false   # module-wide default
}

variable "vm_config" {
  # keep your existing shape; lookup() handles missing key
  type = map(any)
}

variable "environment" {
  description = "Environment tag (e.g., dev/test/prod)."
  type        = string
}

variable "network_name" {
  description = "Name of the VNet (for tagging only)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for all created resources."
  type        = string
}

variable "resource_group_location" {
  description = "Azure region."
  type        = string
}

variable "subnet_id" {
  description = "Target subnet ID for NICs."
  type        = string
}

variable "admin_username" {
  description = "Local admin username for Windows VMs."
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Local admin password (supply via secret store). If null, module generates a strong password."
  type        = string
  default     = null
  sensitive   = true
}

variable "enable_public_ip" {
  description = "Default: assign public IP to VMs (can be overridden per VM with assign_public_ip)."
  type        = bool
  default     = false
}

variable "vm_config" {
  description = "Map of VM names to their configuration."
  type = map(object({
    machine_type        = optional(string)
    machine_description = optional(string)
    assign_public_ip    = optional(bool)
  }))
}

variable "image" {
  description = "Windows image to deploy."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  # Windows Server 2022 Datacenter
  default = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter"
    version   = "latest"
  }
}

variable "os_disk" {
  description = "OS disk configuration."
  type = object({
    caching              = string
    storage_account_type = string
    disk_size_gb         = number
  })
  default = {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 127
  }
}

variable "default_machine_type" {
  description = "Fallback VM size when not set per-VM."
  type        = string
  default     = "Standard_B2ms"
}

variable "firewall_rules" {
  description = <<EOT
Map of NSG rules applied to every VM's NSG.
Example:
{
  rdp = {
    protocol                   = "Tcp"
    destination_port_range     = 3389
    source_address_prefixes    = ["1.2.3.4/32"]
    priority                   = 1001
    description                = "RDP from my IP"
  }
}
EOT
  type = map(object({
    protocol                       = optional(string)   # Tcp/Udp/Asterisk
    direction                      = optional(string)   # Inbound/Outbound
    access                         = optional(string)   # Allow/Deny
    source_port_range              = optional(string)
    destination_port_range         = optional(string)
    source_port_ranges             = optional(list(string))
    destination_port_ranges        = optional(list(string))
    source_address_prefix          = optional(string)
    source_address_prefixes        = optional(list(string))
    destination_address_prefix     = optional(string)
    destination_address_prefixes   = optional(list(string))
    description                    = optional(string)
    priority                       = optional(number)
  }))
  default = {}
}

variable "enable_system_assigned_identity" {
  description = "Enable system-assigned managed identity."
  type        = bool
  default     = false
}

variable "timezone" {
  description = "Windows time zone ID (e.g., 'Central European Standard Time')."
  type        = string
  default     = "UTC"
}

variable "patch_mode" {
  description = "Windows patch mode: AutomaticByOS or AutomaticByPlatform."
  type        = string
  default     = "AutomaticByOS"
}

variable "zones" {
  description = "Optional availability zones to use (e.g., [\"1\"], [\"1\",\"2\"], or null)."
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}

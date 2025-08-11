# ---------------------------
# Locals
# ---------------------------
locals {
  # decide if a VM gets a public IP
  vm_public_ip_enabled = {
    for name, cfg in var.vm_config :
    name => (
      try(cfg.assign_public_ip, null) != null
        ? cfg.assign_public_ip
        : var.enable_public_ip
    )
  }

  tags_common = merge(
    var.tags,
    {
      Environment = var.environment
      Network     = var.network_name
      Module      = "vm-win"
    }
  )
}

# ---------------------------
# Optionally generate an admin password if not provided
# ---------------------------
resource "random_password" "admin" {
  count            = var.admin_password == null ? 1 : 0
  length           = 24
  min_lower        = 4
  min_upper        = 4
  min_numeric      = 4
  min_special      = 2
  override_special = "_%@#-!$"
}

# ---------------------------
# Public IPs (optional, per-VM)
# ---------------------------
resource "azurerm_public_ip" "pip" {
  for_each            = { for k, v in var.vm_config : k => v if local.vm_public_ip_enabled[k] }
  name                = "${each.key}-pip"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.zones
  tags                = merge(local.tags_common, { Role = "public-ip", Vm = each.key })
}

# ---------------------------
# Network Security Group per-VM
# ---------------------------
resource "azurerm_network_security_group" "nsg" {
  for_each            = var.vm_config
  name                = "${each.key}-nsg"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  tags                = merge(local.tags_common, { Role = "nsg", Vm = each.key })
}

# Security rules from firewall_rules map (shared rules applied to all NSGs)
resource "azurerm_network_security_rule" "rules" {
  for_each = {
    for tuple in flatten([
      for vm_name, _cfg in var.vm_config : [
        for rule_name, rule in var.firewall_rules : {
          vm_name  = vm_name
          rname    = rule_name
          rule     = rule
          priority = try(rule.priority, null)
        }
      ]
    ]) : "${tuple.vm_name}:${tuple.rname}" => tuple
  }

  name                        = replace(each.value.rname, "/[^a-zA-Z0-9-]/", "-")
  priority                    = coalesce(each.value.priority, 2000 + index(keys(var.firewall_rules), each.value.rname))
  direction                   = try(each.value.rule.direction, "Inbound")
  access                      = try(each.value.rule.access, "Allow")
  protocol                    = try(each.value.rule.protocol, "Tcp")
  source_port_range           = try(each.value.rule.source_port_range, "*")
  destination_port_range      = try(each.value.rule.destination_port_range, null)
  source_port_ranges          = try(each.value.rule.source_port_ranges, null)
  destination_port_ranges     = try(each.value.rule.destination_port_ranges, null)
  source_address_prefix       = try(each.value.rule.source_address_prefix, null)
  source_address_prefixes     = try(each.value.rule.source_address_prefixes, null)
  destination_address_prefix  = try(each.value.rule.destination_address_prefix, null)
  destination_address_prefixes= try(each.value.rule.destination_address_prefixes, null)

  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg[each.value.vm_name].name
  description                 = try(each.value.rule.description, "rule ${each.value.rname} for ${each.value.vm_name}")
}

# ---------------------------
# NIC per-VM
# ---------------------------
resource "azurerm_network_interface" "nic" {
  for_each            = var.vm_config
  name                = "${each.key}-nic"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "${each.key}-ipcfg"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = local.vm_public_ip_enabled[each.key] ? azurerm_public_ip.pip[each.key].id : null
  }

  tags = merge(local.tags_common, { Role = "nic", Vm = each.key })
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  for_each                  = var.vm_config
  network_interface_id      = azurerm_network_interface.nic[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

# ---------------------------
# Windows VM per-VM
# ---------------------------
resource "azurerm_windows_virtual_machine" "vm" {
  for_each            = var.vm_config
  name                = each.key
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  size                = try(each.value.machine_type, var.default_machine_type)

  # Admin
  admin_username = var.admin_username
  admin_password = coalesce(var.admin_password, one(random_password.admin[*].result))

  # Identity (optional system-assigned)
  identity {
    type = var.enable_system_assigned_identity ? "SystemAssigned" : "None"
  }

  # Networking
  network_interface_ids = [azurerm_network_interface.nic[each.key].id]
  zones                 = var.zones

  # Image
  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }

  # OS Disk
  os_disk {
    name                 = "${each.key}-osdisk"
    caching              = var.os_disk.caching
    storage_account_type = var.os_disk.storage_account_type
    disk_size_gb         = var.os_disk.disk_size_gb
  }

  # Optional WinRM HTTPS listener or custom_data can be added later if needed
  # winrm_listener {
  #   protocol        = "Https"
  #   certificate_url = var.winrm_certificate_url
  # }

  # Timezone and patching options (sane defaults)
  timezone            = var.timezone
  patch_mode          = var.patch_mode
  provision_vm_agent  = true

  tags = merge(
    local.tags_common,
    {
      Role          = "vm"
      Vm            = each.key
      Description   = try(each.value.machine_description, "windows")
      OS            = "Windows"
      OSImage       = "${var.image.publisher}:${var.image.offer}:${var.image.sku}:${var.image.version}"
    }
  )
}

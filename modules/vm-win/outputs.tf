output "vm_ids" {
  description = "IDs of the Windows VMs."
  value       = { for k, v in azurerm_windows_virtual_machine.vm : k => v.id }
}

output "vm_private_ips" {
  description = "Private IPs of NICs."
  value       = {
    for k, v in azurerm_network_interface.nic :
    k => one(v.ip_configuration[*].private_ip_address)
  }
}

output "vm_public_ips" {
  description = "Public IP addresses (only where enabled)."
  value       = {
    for k, v in azurerm_public_ip.pip :
    k => v.ip_address
  }
}

output "admin_username" {
  value       = var.admin_username
  description = "Admin username used for the Windows VMs."
}

output "admin_password" {
  value       = coalesce(var.admin_password, one(random_password.admin[*].result))
  description = "Admin password used for the Windows VMs."
  sensitive   = true
}

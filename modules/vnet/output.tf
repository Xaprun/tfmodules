output "subnet_ids" {
  description = "A map of subnet names to subnet IDs"
  value = { for s in azurerm_subnet.subnet : s.name => s.id }
}
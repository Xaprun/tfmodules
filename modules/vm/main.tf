
# resource "azurerm_network_interface" "main" {
#  for_each            = var.vm_config
#  name                = "${each.key}-nic"
#  location            = var.resource_group_location
#  resource_group_name = var.resource_group_name
#
# ip_configuration {
#    name                          = "${each.key}-ip-config"
#    subnet_id = var.subnet_id
#    # subnet_id                     = data.azurerm_subnet.public_subnet.id 
#    private_ip_address_allocation = "Dynamic"
#
#    public_ip_address_id = azurerm_public_ip.public_ip[each.key].id
#  }
#}

# resource "azurerm_linux_virtual_machine" "vm" {
#  for_each            = var.vm_config
#  name                = each.key
#  resource_group_name = var.resource_group_name
#  location            = var.resource_group_location
#  size                = each.value.machine_type
#  admin_username = var.admin_username 
#  
#  admin_ssh_key {
#    username     = var.admin_username
#    public_key = file(var.admin_ssh_key_path)
#  }
#
#  network_interface_ids = [azurerm_network_interface.main[each.key].id]
#
#  os_disk {
#    caching              = "ReadWrite"
#    storage_account_type = "Standard_LRS"
#  }

#  source_image_reference {
#    publisher = "Debian"
#    offer     = "debian-11"
#    sku       = "11"
#    version   = "latest"
#  }
  
  # custom_data =file(var.custom_data_file)
#  custom_data = filebase64(var.custom_data_file)
  # custom_data = var.custom_data_file != "" ? base64encode(file(var.custom_data_file)) : null
  # custom_data = base64encode(<<-EOF
  #            #!/bin/bash
  #            # Aktualizacja pakietów
  #            apt-get update -y
  #            # Instalacja narzędzi do analizy sieci (net-tools)
  #            apt-get install -y net-tools
  #          EOF
  # )
#
#
#  tags = {
#    Environment = var.environment
#    Description = each.value.machine_description
#  }
#}

##############################################
locals {
  # Decide which VMs should get a Public IP
  public_ip_vms = {
    for k, v in var.vm_config :
    k => v
    if lookup(v, "assign_public_ip", var.enable_public_ip)
  }

  _custom_data = (
    var.custom_data != null && length(trimspace(var.custom_data)) > 0
    ? base64encode(var.custom_data)
    : (
        var.custom_data_file != null && length(trimspace(var.custom_data_file)) > 0
        ? filebase64(var.custom_data_file)
        : null
      )
  )
}

resource "azurerm_public_ip" "public_ip" {
  for_each            = local.public_ip_vms
  name                = "${each.key}-public-ip"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "main" {
  for_each            = var.vm_config
  name                = "${each.key}-nic"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "${each.key}-ip-config"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = try(azurerm_public_ip.public_ip[each.key].id, null)
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each            = var.vm_config
  name                = each.key
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  size                = each.value.machine_type

  admin_username = var.admin_username
  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.admin_ssh_key_path)
  }

  network_interface_ids = [azurerm_network_interface.main[each.key].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-11"
    sku       = "11"
    version   = "latest"
  }

  custom_data = local._custom_data

  tags = {
    Environment = var.environment
    Description = lookup(each.value, "machine_description", "")
  }
}


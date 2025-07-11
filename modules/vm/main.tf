##### Works only if resource exists #########
# data "azurerm_subnet" "public_subnet" {
#  # name    = "prod-public-subnet-01"
#  name      = var.public_subnet_name
#  virtual_network_name = var.network_name
#  resource_group_name  = var.resource_group_name 
# }
#############################################

resource "azurerm_public_ip" "public_ip" {
  for_each            = var.vm_config
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
    subnet_id = var.subnet_id
    # subnet_id                     = data.azurerm_subnet.public_subnet.id 
    private_ip_address_allocation = "Dynamic"

    public_ip_address_id = azurerm_public_ip.public_ip[each.key].id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each            = var.vm_config
  name                = each.key
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  size                = each.value.machine_type
  # admin_username      = "kasia"
  admin_username = var.admin_username 
  
  admin_ssh_key {
    # username   = "kasia"
    # public_key = file("${path.module}/ssh/kasia_key.pub")
    username     = var.admin_username
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

  # custom_data = var.custom_data_file != "" ? base64encode(file(var.custom_data_file)) : null
  custom_data = base64encode(<<-EOF
              #!/bin/bash
              # Aktualizacja pakietów
              apt-get update -y
              # Instalacja narzędzi do analizy sieci (net-tools)
              apt-get install -y net-tools
            EOF
  )


  tags = {
    Environment = var.environment
    Description = each.value.machine_description
  }
}

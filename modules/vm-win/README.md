# vm-win (Azure Windows VM Module)

Creates one or more Windows Server VMs with:
- Per-VM NIC, optional Public IP (override with `assign_public_ip`)
- Per-VM NSG built from a shared `firewall_rules` map
- Sensible defaults (Windows Server 2022, Premium OS disk)
- Optional system-assigned identity
- Neat tagging

## Inputs (highlights)
- `vm_config`: map of VM names → { machine_type?, machine_description?, assign_public_ip? }
- `enable_public_ip`: module-wide default (false)
- `firewall_rules`: NSG rules applied to every VM's NSG
- `admin_username`, `admin_password` (if `admin_password` is null, module generates one)
- `image`, `os_disk`, `zones`, `timezone`, `patch_mode`

## Outputs
- `vm_ids`, `vm_private_ips`, `vm_public_ips`, `admin_username`, `admin_password` (sensitive)

## Example

```hcl
module "vm_win_01" {
  source                  = "git::https://github.com/YourOrg/yourrepo.git//modules/vm-win?ref=main"
  environment             = var.environment
  network_name            = "${local.prefix}-vnet"
  resource_group_name     = azurerm_resource_group.rg-01.name
  resource_group_location = var.location
  subnet_id               = module.vnet-01.subnet_ids["subnet-win"]

  # default off, override per-VM
  enable_public_ip = false

  vm_config = {
    "${local.prefix}-vm-wi01" = {
      machine_type        = "Standard_B2ms"
      machine_description = "public"
      assign_public_ip    = true
    }
  }

  firewall_rules = {
    rdp = {
      protocol                    = "Tcp"
      destination_port_range      = 3389
      source_address_prefixes     = ["1.2.3.4/32"] # replace with your IP
      priority                    = 1001
      description                 = "RDP"
    }
  }
}

module "vm_win_02" {
  source                  = "git::https://github.com/YourOrg/yourrepo.git//modules/vm-win?ref=main"
  environment             = var.environment
  network_name            = "${local.prefix}-vnet"
  resource_group_name     = azurerm_resource_group.rg-01.name
  resource_group_location = var.location
  subnet_id               = module.vnet-01.subnet_ids["subnet-win-prv"]

  vm_config = {
    "${local.prefix}-vm-wi02" = {
      machine_type        = "Standard_B2ms"
      machine_description = "private"
    }
  }

  firewall_rules = {} # private; no inbound
}

########################
### ADDITIONAL NOTES ###
########################


---

### How to use with your current stack

Once you commit the module, your root config can reference it like:

```hcl
module "vm_win_01" {
  source                  = "git::https://github.com/Xaprun/tfmodules.git//modules/vm-win?ref=main"
  environment             = var.environment
  network_name            = "${local.prefix}-vnet"
  resource_group_name     = azurerm_resource_group.rg-01.name
  resource_group_location = var.location
  subnet_id               = module.vnet-01.subnet_ids["subnet-win"]

  enable_public_ip = false

  vm_config = {
    "${local.prefix}-vm-wi01" = {
      machine_type        = "Standard_B2ms"
      machine_description = "public"
      assign_public_ip    = true
    }
  }

  firewall_rules = {
    rdp = {
      protocol                 = "Tcp"
      destination_port_range   = 3389
      source_address_prefixes  = ["YOUR_IP/32"]
      priority                 = 1001
    }
  }
}

module "vm_win_02" {
  source                  = "git::https://github.com/Xaprun/tfmodules.git//modules/vm-win?ref=main"
  environment             = var.environment
  network_name            = "${local.prefix}-vnet"
  resource_group_name     = azurerm_resource_group.rg-01.name
  resource_group_location = var.location
  subnet_id               = module.vnet-01.subnet_ids["subnet-win-prv"]

  vm_config = {
    "${local.prefix}-vm-wi02" = {
      machine_type        = "Standard_B2ms"
      machine_description = "private"
    }
  }

  firewall_rules = {}
}


resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstateenv${var.environment}"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 90
    }
  }

  tags = {
    environment = var.environment
    purpose     = "terraform-state"
  }
}

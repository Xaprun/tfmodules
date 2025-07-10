resource "azurerm_storage_account" "tfstate" {
  name                            = "tfstateenv${var.environment}"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  is_hns_enabled                  = true
  infrastructure_encryption_enabled = true

  tags = {
    environment = var.environment
    purpose     = "terraform-state"
  }
}

resource "azurerm_storage_account_blob_properties" "default" {
  storage_account_id = azurerm_storage_account.tfstate.id

  versioning_enabled = true
  delete_retention_policy {
    days = 90
  }
}

resource "azurerm_storage_account_blob_restore_policy" "default" {
  storage_account_id = azurerm_storage_account.tfstate.id
  enabled            = true
  days               = 90
}

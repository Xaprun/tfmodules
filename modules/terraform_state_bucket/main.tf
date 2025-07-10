resource "azurerm_storage_account" "example" {
  name                     = "examplestorageacc"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    delete_retention_policy {
      days = 90
    }

    restore_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 90
    }
  }
}

data "azurerm_client_config" "this" {}

module "managed_identity" {
  source              = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.3.4"
  name = "${var.app_name}-uami"
  resource_group_name =              var.spoke_resource_group_name
  location            = var.location
  tags                = var.tags
  
  # lock = merge(local.lock, {
  #   name = "mi-lock-${var.environment}-${var.app_name}${var.instance}"
  # })
  # role_assignments = merge(
  #   {
  #     runner_mi_contributor_role = {
  #       role_definition_id_or_name = "Contributor"
  #       principal_id               = data.azuread_service_principal.this.object_id
  #     }
  #   },
  #   var.managed_identity.role_assignments
  # )
    depends_on = [azurerm_resource_group.spoke_rg]
}

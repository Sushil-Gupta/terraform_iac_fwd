locals {
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.container_registry.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : {
        asg_key         = asg_k
        pe_key          = pe_k
        asg_resource_id = asg_v
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc }
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}

# Create new Azure Container Registry
resource "azurerm_container_registry" "this" {
  name                = var.container_registry.name
  resource_group_name = var.container_registry.resource_group_name
  location            = var.location
  sku                 = var.container_registry.sku
  admin_enabled       = false
  tags                = var.tags
  
  depends_on = [azurerm_resource_group.spoke_rg]
}

resource "azurerm_management_lock" "this" {
  count = var.container_registry.lock != null ? 1 : 0

  lock_level = var.container_registry.lock.kind
  name       = coalesce(var.container_registry.lock.name, "lock-${var.container_registry.name}")
  scope      = azurerm_container_registry.this.id
  notes      = var.container_registry.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.container_registry.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_container_registry.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

# The PE resource when we are managing the private_dns_zone_group block:
resource "azurerm_private_endpoint" "this" {
  for_each = { for k, v in var.container_registry.private_endpoints : k => v if var.container_registry.private_endpoints_manage_dns_zone_group }

  location                      = var.location
  name                          = each.value.name != null ? each.value.name : "pe-${var.container_registry.name}"
  resource_group_name           = var.container_registry.resource_group_name
  subnet_id                     = module.subnets[each.value.subnet_key].resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = merge(var.tags, each.value.tags)

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.container_registry.name}"
    private_connection_resource_id = azurerm_container_registry.this.id
    subresource_names              = ["registry"]
  }
  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = "registry"
      subresource_name   = "registry"
    }
  }
  dynamic "private_dns_zone_group" {
    for_each = length(each.value.privatednszone_key) > 0 ? ["this"] : []

    content {
      name                 = each.value.private_dns_zone_group_name
      private_dns_zone_ids = [module.private_dns[each.value.privatednszone_key].resource_id]
    }
  }
}

# The PE resource when we are **not** managing the private_dns_zone_group block, such as when using Azure Policy:
resource "azurerm_private_endpoint" "this_unmanaged_dns_zone_groups" {
  for_each = { for k, v in var.container_registry.private_endpoints : k => v if !var.container_registry.private_endpoints_manage_dns_zone_group }

  location                      = var.location
  name                          = each.value.name != null ? each.value.name : "pe-${var.container_registry.name}"
  resource_group_name           = var.container_registry.resource_group_name
  subnet_id                     = module.subnets[each.value.subnet_key].resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = merge(var.tags, each.value.tags)

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.container_registry.name}"
    private_connection_resource_id = azurerm_container_registry.this.id
    subresource_names              = ["registry"]
  }
  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = "registry"
      subresource_name   = "registry"
    }
  }

  lifecycle {
    ignore_changes = [private_dns_zone_group]
  }
}

resource "azurerm_private_endpoint_application_security_group_association" "this" {
  for_each = local.private_endpoint_application_security_group_associations

  application_security_group_id = each.value.asg_resource_id
  private_endpoint_id           = azurerm_private_endpoint.this[each.value.pe_key].id
}

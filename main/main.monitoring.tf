module "log_analytics_workspace" {
  source = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.4.2"
  enable_telemetry                          = true
  location                                  = var.location
  resource_group_name                       = var.spoke_resource_group_name
  name                                      = "${var.app_name}-${var.environment}-law"
  log_analytics_workspace_retention_in_days = 30
  log_analytics_workspace_sku               = "PerGB2018"
  log_analytics_workspace_identity = {
    type = "SystemAssigned"
  }
  tags = var.tags
  depends_on = [azurerm_resource_group.spoke_rg]
}
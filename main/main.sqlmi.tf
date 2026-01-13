# Data block to reference existing Azure SQL Managed Instance
# COMMENTED OUT: Waiting for customer to provide actual SQL MI details
# Uncomment when SQL MI "forward-qa-sql" is available in rg-fwd-qa
# data "azurerm_mssql_managed_instance" "existing_sql_mi" {
#   name                = var.sql_managed_instance.name
#   resource_group_name = var.sql_managed_instance.resource_group_name
# }

# Outputs for application teams and other resources
# COMMENTED OUT: Uncomment when data block above is active
# output "sql_managed_instance_fqdn" {
#   description = "The fully qualified domain name of the SQL Managed Instance for connection strings"
#   value       = data.azurerm_mssql_managed_instance.existing_sql_mi.fqdn
#   sensitive   = false
# }

# output "sql_managed_instance_id" {
#   description = "The resource ID of the SQL Managed Instance"
#   value       = data.azurerm_mssql_managed_instance.existing_sql_mi.id
#   sensitive   = false
# }

# output "sql_managed_instance_administrator_login" {
#   description = "The administrator login name for the SQL Managed Instance"
#   value       = data.azurerm_mssql_managed_instance.existing_sql_mi.administrator_login
#   sensitive   = false
# }

# output "sql_managed_instance_dns_zone_id" {
#   description = "The DNS Zone ID for the SQL Managed Instance (used for private DNS configuration)"
#   value       = data.azurerm_mssql_managed_instance.existing_sql_mi.dns_zone_id
#   sensitive   = false
# }

# output "sql_managed_instance_subnet_id" {
#   description = "The subnet ID where SQL Managed Instance is deployed"
#   value       = data.azurerm_mssql_managed_instance.existing_sql_mi.subnet_id
#   sensitive   = false
# }

# output "sql_managed_instance_vcores" {
#   description = "Number of vCores configured for the SQL Managed Instance"
#   value       = data.azurerm_mssql_managed_instance.existing_sql_mi.vcores
#   sensitive   = false
# }

# output "sql_managed_instance_storage_size_in_gb" {
#   description = "Storage size in GB for the SQL Managed Instance"
#   value       = data.azurerm_mssql_managed_instance.existing_sql_mi.storage_size_in_gb
#   sensitive   = false
# }

# output "sql_managed_instance_license_type" {
#   description = "License type for the SQL Managed Instance (LicenseIncluded or BasePrice)"
#   value       = data.azurerm_mssql_managed_instance.existing_sql_mi.license_type
#   sensitive   = false
# }

# output "sql_managed_instance_location" {
#   description = "The Azure region where the SQL Managed Instance is deployed"
#   value       = data.azurerm_mssql_managed_instance.existing_sql_mi.location
#   sensitive   = false
# }

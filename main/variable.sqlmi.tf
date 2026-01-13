# Variable for existing SQL Managed Instance (data source)
variable "sql_managed_instance" {
  description = "Configuration for referencing an existing Azure SQL Managed Instance"
  type = object({
    name                = string
    resource_group_name = string
  })
}
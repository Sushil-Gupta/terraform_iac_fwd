variable "log_analytics_workspace" {
  description = "Details of the Log Analytics workspace for diagnostics."
  type        = object({
    name                = string
    resource_group_name = string
    tags                            = optional(map(string), {}) 
  })
}
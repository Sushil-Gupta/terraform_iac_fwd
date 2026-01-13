
# App specific variables
variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "environment" {
  description = "The environment in which the resources are deployed"
  type        = string
}

variable "instance" {
  description = "The instance number for a public subnet"
  type        = string
}

# Subscription and Resource Group variables
variable "subscription_id" {
  description = "The subscription ID"
  type        = string
}

variable "spoke_resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure location where the resources will be deployed."
  type        = string
}

variable "tags" {
  description = "Tags to be applied to the resources"
  type        = map(string)
  default     = {}
}
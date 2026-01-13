## APP Gateway variables
variable "app_gateways" {
  description = "Configuration for Azure Application Gateway"
  type = map(object({    
    name = string
    sku = object({
      name     = string
      tier     = string
      capacity = optional(number)
    })
    backend_address_pools = map(object({
      name         = string
      fqdns        = optional(set(string))
      ip_addresses = optional(set(string))
    }))
    autoscale_configuration = optional(object({
      min_capacity = number
      max_capacity = number
    }), null)
    # frontend_ip_key = string
    frontend_ip_configuration_name = string
    backend_http_settings = map(object({
      cookie_based_affinity               = optional(string, "Disabled")
      name                                = string
      port                                = number
      protocol                            = string
      affinity_cookie_name                = optional(string)
      host_name                           = optional(string)
      path                                = optional(string)
      pick_host_name_from_backend_address = optional(bool)
      probe_name                          = optional(string)
      request_timeout                     = optional(number)
      trusted_root_certificate_names      = optional(list(string))
      authentication_certificate = optional(list(object({
        name = string
      })))
      connection_draining = optional(object({
        drain_timeout_sec          = number
        enable_connection_draining = bool
      }))
    }))
    frontend_ports = map(object({
      name = string
      port = number
    }))
    gateway_ip_configuration = object({
      name       = optional(string)
      subnet_key = string
    })
    http_listeners = map(object({
      name                           = string
      frontend_port_name             = string
      frontend_ip_configuration_name = optional(string)
      firewall_policy_id             = optional(string)
      require_sni                    = optional(bool)
      host_name                      = optional(string)
      host_names                     = optional(list(string))
      ssl_certificate_name           = optional(string)
      ssl_profile_name               = optional(string)
      custom_error_configuration = optional(list(object({
        status_code           = string
        custom_error_page_url = string
      })))
    }))
    probe_configurations = map(object({
      name                                      = string
      host                                      = optional(string)
      interval                                  = number
      timeout                                   = number
      unhealthy_threshold                       = number
      protocol                                  = string
      port                                      = optional(number)
      path                                      = string
      pick_host_name_from_backend_http_settings = optional(bool)
      minimum_servers                           = optional(number)
      match = optional(object({
        body        = optional(string)
        status_code = optional(list(string))
      }))
    }))
    ssl_certificates = optional(map(object({
    name                = string
    file_path                = optional(string,null)
    password            = optional(string)
    key_vault_details = optional(object({
      resource_group_name = string
      key_vault_name = string
      secret_name  = string
    }),null)
    })),null)
    request_routing_rules = optional(map(object({
      name                        = string
      rule_type                   = string
      http_listener_name          = string
      backend_address_pool_name   = string
      priority                    = optional(number)
      url_path_map_name           = optional(string)
      backend_http_settings_name  = optional(string)
      redirect_configuration_name = optional(string)
      rewrite_rule_set_name       = optional(string)
    })),null)
    waf_configuration = object({
      enabled                  = bool
      file_upload_limit_mb     = optional(number)
      firewall_mode            = string
      max_request_body_size_kb = optional(number)
      request_body_check       = optional(bool)
      rule_set_type            = optional(string)
      rule_set_version         = string
      disabled_rule_group = optional(list(object({
        rule_group_name = string
        rules           = optional(list(number))
      })))
      exclusion = optional(list(object({
        match_variable          = string
        selector                = optional(string)
        selector_match_operator = optional(string)
      })))
    })
    url_path_map_configurations = optional(map(object({
        name                                = string
        default_redirect_configuration_name = optional(string)
        default_rewrite_rule_set_name       = optional(string)
        default_backend_http_settings_name  = optional(string)
        default_backend_address_pool_name   = optional(string)
        path_rules = map(object({
          name                        = string
          paths                       = list(string)
          backend_address_pool_name   = optional(string)
          backend_http_settings_name  = optional(string)
          redirect_configuration_name = optional(string)
          rewrite_rule_set_name       = optional(string)
          firewall_policy_id          = optional(string)
        }))
    })),null)
    # managed_identities =  optional(map(object({
    #   system_assigned            = optional(bool, false)
    #   user_assigned_resource_name = optional(set(string), [])
    # })),null)
    zones             = optional(set(string), ["1"])
    tags              = optional(map(string), {})
    log_categories    = optional(list(string), ["allLogs"])
    log_groups        = optional(list(string), [])
    metric_categories = optional(list(string), [])
  }))
}

# variable "app_gateway_pips" {
#   description = "The public ip for app gateway"
#   type = map(object({
#     name      = string
#     tags              = optional(map(string), {})
#     log_categories    = optional(list(string), [])
#     log_groups        = optional(list(string), [])
#     metric_categories = optional(list(string), [])
#   }))
# }

variable "app_gateway_policy"{
     description = "Configuration for Azure Application Gateway"

     type = object({
        name = string
        enable_telemetry = optional(bool)
        lock= optional(object({
            kind = string
            name = optional(string, null)
        }))
        managed_rules= object({
            exclusion = optional(map(object({
                match_variable          = string
                selector                = string
                selector_match_operator = string
                excluded_rule_set = optional(object({
                    type    = optional(string)
                    version = optional(string)
                    rule_group = optional(list(object({
                      excluded_rules  = optional(list(string))
                      rule_group_name = string
                })))
               }))
            })))
            managed_rule_set = map(object({
              type    = optional(string)
              version = string
              rule_group_override = optional(map(object({
                rule_group_name = string
                rule = optional(list(object({
                  action  = optional(string)
                  enabled = optional(bool)
                  id      = string
                })))
              })))
            }))
        })
        custom_rules = map(object({
          action               = string
          enabled              = optional(bool)
          group_rate_limit_by  = optional(string)
          name                 = optional(string)
          priority             = number
          rate_limit_duration  = optional(string)
          rate_limit_threshold = optional(number)
          rule_type            = string
          match_conditions = map(object({
            match_values       = optional(list(string))
            negation_condition = optional(bool)
            operator           = string
            transforms         = optional(set(string))
            match_variables = list(object({
              selector      = optional(string)
              variable_name = string
            }))
          }))
        }))
        policy_settings = object({
          enabled                                   = optional(bool)
          file_upload_limit_in_mb                   = optional(number)
          js_challenge_cookie_expiration_in_minutes = optional(number)
          max_request_body_size_in_kb               = optional(number)
          mode                                      = optional(string)
          request_body_check                        = optional(bool)
          request_body_inspect_limit_in_kb          = optional(number)
          log_scrubbing = optional(object({
            enabled = optional(bool)
            rule = optional(list(object({
              enabled                 = optional(bool)
              match_variable          = string
              selector                = optional(string)
              selector_match_operator = optional(string)
            })))
          }))
        })
     })
}
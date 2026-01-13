subscription_id                   = "95642268-5116-484d-9b88-7dfce8c20ce4"
spoke_resource_group_name         = "rg-fwd-qa"
location                          = "westus3"
app_name                          = "fwd"
environment                       = "qa"
instance                          = ""
spoke_vnet   = {
    name                = "vnet-fwd-qa"
    address_prefix      = "10.6.0.0/16"
}
hub_vnet   = {
    name                     = "<<HUB VNET NAME>>"
    resource_group_name      = "<<HUB RG NAME>>"
}
route_table = {
    name = "rt-fwd-qa"
    firewallPrivateIp = "<<HUB FIREWALL IP>>"
}
tags = {
    "environment"  = "qa"
    "Criticality"  = "Low"
}
log_analytics_workspace = {
    name                = "law-fwd-qa"
    resource_group_name = "rg-fwd-qa"
}


subnets = {
  "aks" = {
    name                            = "subnet-clusternodes-qa"
    address_prefix                  = "10.6.30.0/24"
    default_outbound_access_enabled = true
  }
  "appgw" = {
    name                            = "snet-appgateway-qa"
    address_prefix                  = "10.6.32.0/24"
    default_outbound_access_enabled = true
    delegation = [
      {
        name = "appgw-delegation"
        service_delegation = {
          name = "Microsoft.Network/applicationGateways"
        }
      }
    ]
  }
  "private-endpoint" = {
    name                            = "snet-privatelink-qa"
    address_prefix                  = "10.6.31.0/24"
    default_outbound_access_enabled = true
  }
}

private_dns_zones = {
    "aks" = {
      domain_name = "privatelink.westus3.azmk8s.io"
    }
    # "keyvault" = {
    #   domain_name = "privatelink.vaultcore.azure.net"
    # }
    "acr" = {
      domain_name = "privatelink.azurecr.io"
    }
    "storage-blob" = {
      domain_name = "privatelink.blob.core.windows.net"
    }
}

nsg = {
  "aks" = {
    name = "nsg-aks-qa"
  }
  "appgw" = {
    name = "nsg-agw-qa"
    security_rules = {
    "rule01" = {
      name                       = "Allow443InBound"
      access                     = "Allow"
      destination_address_prefix = "*"
      destination_port_range     = "443"
      direction                  = "Inbound"
      priority                   = 100
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
    }
    "rule02" = {
      name                       = "AllowControlPlaneV2SKU"
      access                     = "Allow"
      destination_address_prefix = "*"
      destination_port_ranges    = ["65200-65535"]
      direction                  = "Inbound"
      priority                   = 200
      protocol                   = "Tcp"
      source_address_prefix      = "GatewayManager"
      source_port_range          = "*"
    }
    "rule03" = {
      name                       = "Allow80InBound"
      access                     = "Allow"
      destination_address_prefix = "*"
      destination_port_ranges    = ["80"]
      direction                  = "Inbound"
      priority                   = 300
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
    }
   }
  }
  "private-endpoint" = {
    name = "nsg-pe-qa"
    security_rules = {
      "rule01" = {
        name                       = "rule011"
        access                     = "Deny"
        destination_address_prefix = "*"
        destination_port_range     = "80-88"
        direction                  = "Outbound"
        priority                   = 100
        protocol                   = "Tcp"
        source_address_prefix      = "*"
        source_port_range          = "*"
      }
      "rule02" = {
        name                       = "rule012"
        access                     = "Allow"
        destination_address_prefix = "*"
        destination_port_ranges    = ["80", "443"]
        direction                  = "Inbound"
        priority                   = 200
        protocol                   = "Tcp"
        source_address_prefix      = "*"
        source_port_range          = "*"
      }
    }
  }
}

# app_gateway_pips = {
#   "A" = {
#     name = "GAC-FWAF-01-FWB-A-feip-pip"
#   }
#   # "B" = {
#   #   name = "GAC-FWAF-01-FWB-B-feip-pip"
#   # }
# }

app_gateways = {
  "A" ={
    name                = "GAC-FWAF-01-FWB-A"
    tags = {}
    frontend_ip_key    = "A"
    frontend_ip_configuration_name  = "GAC-FWAF-01-FWB-A-feip"
    sku = {
      name     = "WAF_v2"
      tier     = "WAF_v2"
      capacity = 0
    }
    autoscale_configuration = {
        min_capacity = 1
        max_capacity = 2
    }
    backend_address_pools = {
      "aks-pool" = {
        name = "aks-pool"
      }
    }
    # ssl_certificates = []
    gateway_ip_configuration = {
      name      = "GAC-FWAF-01-FWB-A-gwip"
      subnet_key = "appgw"
    }
    backend_http_settings = {
      "setting1" = {
        name                  = "setting1"
        cookie_based_affinity = "Disabled"
        port                  = 80
        protocol              = "Http"
        path                 = "/"
        probe_name            = "Probe1"
      }
    }
    request_routing_rules = {
        rule-1 = {
      name                       = "rule-1"
      rule_type                  = "Basic"
      http_listener_name         = "listener1"
      backend_address_pool_name  = "aks-pool"
      backend_http_settings_name = "setting1"
      priority                   = 100
    #   rewrite_rule_set_name      = "my-rewrite-rule-set"
    }
    }
    frontend_ports = {
      "port01" = {
        name = "port01"
        port = 80
      }
    }
    http_listeners = {
      "listener1" = {
        name                           = "listener1"
        frontend_ip_configuration_name = "GAC-FWAF-01-FWB-A-feip"
        host_name          = null
        frontend_port_name             = "port01"
      }
    }
    waf_configuration = {
        enabled          = true
        firewall_mode    = "Prevention"
        rule_set_version = "3.2"
    }
    probe_configurations = {
      "probe1" = {
        name                                      = "Probe1"
        interval                                  = 30
        timeout                                   = 10
        unhealthy_threshold                       = 3
        protocol                                  = "Http"
      port                                      = 80
      path                                      = "/"
      pick_host_name_from_backend_http_settings = false
      host                                = "privatelink.contoso.com"
      match = {
        status_code = ["200-399"]
      }
      }
      
    }
    zones = ["1", "2", "3"]
  }  
}

app_gateway_policy = {
  name = "GAC-FWAF-01-FWB-A-policy"
  policy_settings = {
    enabled                                   = false
    file_upload_limit_in_mb                   = 100
    js_challenge_cookie_expiration_in_minutes = 5
    max_request_body_size_in_kb               = 128
    mode                                      = "Prevention"
    request_body_check                        = true
    request_body_inspect_limit_in_kb          = 128
  }
  custom_rules = {
    example_rule_1 = {
    name      = "BlockSpecificIP"
    priority  = 1
    rule_type = "MatchRule"

    match_conditions = {
         condition_1 = {
      match_variables = [{
        variable_name = "RemoteAddr"
      }]
      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["192.168.1.1"] # Replace with the IP address to block
    }
    }
    action = "Block"
    }
  }
  managed_rules = {
    managed_rule_set = {
        example_rule_set = {
            type    = "OWASP"
            version = "3.2"
        }
    }
    exclusion = {}
  }
}

azure_kubernetes_service = {
    name                = "forward-aks-cluster-qa"
    sku_tier                           = "Free" # QA environment - cost-effective tier
    oidc_issuer_enabled                = true
    workload_identity_enabled          = true
    role_based_access_control_enabled  = true
    dns_prefix_private_cluster         = "forward-aks-cluster-qa-private"
    private_cluster_enabled            = true
    private_dns_zone_key               = "aks"
    kubernetes_version                 = "1.32" # Latest stable non-LTS version
    private_cluster_public_fqdn_enabled = true
    ingress_application_gateway = {
      gateway_key = "A"
   }
    run_command_enabled = true
    default_node_pool = {
        name                 = "default"
        vm_size              = "Standard_D8s_v5"
        os_disk_size_gb      = 128
        os_sku               = "AzureLinux"
        min_count            = 1
        max_count            = 3
        # node_count           = 1
        auto_scaling_enabled = true
        max_pods             = 30
        vnet_subnet_key       = "aks"
        zones                = ["1"]
        temporary_name_for_rotation = "default1"
      }
    node_pools  = {
       unp1 = {
        name                 = "linuxpldev"
        vm_size              = "Standard_D8s_v5"
        os_disk_size_gb      = 128
        os_sku               = "AzureLinux"
        min_count            = 1
        max_count            = 3
        # node_count           = 1
        auto_scaling_enabled = true
        max_pods             = 30
        vnet_subnet_key       = "aks"
        zones                = ["1"]
        temporary_name_for_rotation = "linuxpldev1"
      }
    }
    network_profile = {
        network_plugin       = "azure" 
        network_plugin_mode  = "overlay"
        outbound_type        = "userDefinedRouting"
        # service_cidr         = "10.0.97.192/26"
        # dns_service_ip       = "10.0.97.199"
    }
    # Configure Managed Identity
    managed_identities = {
        system_assigned  = false
        user_assigned_resource_ids = []
    }    
    role_assignments = {
      # rbac_role = {
      #   role_definition_id_or_name = "Azure Kubernetes Service RBAC Reader"
      #   principal_id               = "bbd73755-da5c-4284-a595-1cddb969fe91"
      #   principal_type = "Group"    
      # }
      # cluster_user_role = {
      #   role_definition_id_or_name = "Azure Kubernetes Service Cluster User Role"
      #   principal_id               = "bbd73755-da5c-4284-a595-1cddb969fe91"
      #   principal_type = "Group"    
      # }
      # Namespace_contributor = {
      #   role_definition_id_or_name = "Azure Kubernetes Service Namespace Contributor"
      #   principal_id               = "bbd73755-da5c-4284-a595-1cddb969fe91"
      #   principal_type = "Group"    
      # }
    }
#     private_endpoints = {
#     "primary" = {
#        subnet_key         = "private-endpoint"
#         privatednszone_key = "aks"
#         subresource_name   = "management"
#     }
#   }
    private_endpoints_manage_dns_zone_group = false
    # Configure Azure AD Role-Based Access Control
    azure_active_directory_role_based_access_control = {
      azure_rbac_enabled = true
      admin_group_object_ids = []
    }
}
# For Existing Key Vault 
key_vault = {
  name                = "temp-kv-placeholder"
  resource_group_name = "temp-rg-placeholder"
}

# OLD CONFIGURATION (commented out - for creating new Key Vault)
# key_vault = {
#     name = "akv-fwd-fru4u5ccyuarq-qa"
#     sku_name = "standard"
#     tags = {}
#     network_acls = {
#       bypass                     = "None"
#       default_action             = "Deny"
#       ip_rules                   = []
#     }
#     private_endpoints = {
#       "akv-dev-pe" = {
#         subnet_key         = "private-endpoint"
#         privatednszone_key = "keyvault"
#         subresource_name   = "vault"
#       }
#     }
#     role_assignments = {}
# }
container_registry = {
  name = "fwdcontainerregistryqa"
  resource_group_name = "rg-fwd-qa"
  sku = "Premium"
  private_endpoints = {
    "primary" = {
      name                         = "acr-fwd-qa-pe"
       subnet_key         = "private-endpoint"
        privatednszone_key = "acr"
    }
  }
  private_endpoints_manage_dns_zone_group = true
}

storage_accounts = {
  "stg_acc_key" = {
    name                      = "fwdstorageaccqa"
    account_tier              = "Standard"
    storage_accounts_kind      = "StorageV2"
    account_replication_type  = "LRS"
    shared_access_key_enabled = false
    private_endpoints = {
      "stg-fwd-qa-pe" = {
        name               = "stg-fwd-qa-pe"
        subnet_key         = "private-endpoint"
        subresource_name   = "blob"
        privatednszone_key = "storage-blob"
      }
    }
  }
}

# Existing SQL Managed Instance (customer-provided resource)
# Details: 4 vCores, 256 GB storage, General Purpose Gen5, Zone-redundant, West US 3
sql_managed_instance = {
  name                = "forward-qa-sql"
  resource_group_name = "rg-fwd-qa"
}
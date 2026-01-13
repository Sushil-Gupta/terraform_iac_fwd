# Prerequisites 

This is the starting point for the instructions on deploying this reference implementation. There is required access and tooling you'll need in order to accomplish this.

## Azure Portal

- An Azure subscription
- The following resource providers [registered](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-providers-and-types#register-resource-provider):
  - `Microsoft.App`
  - `Microsoft.ContainerRegistry`
  - `Microsoft.ContainerService`
  - `Microsoft.KeyVault`, etc.
- To successfully run the shared IaC scripts, the following roles are required at the subscription level
  - Contributor role is required at the subscription level to create resource groups and perform deployments.
  - User Access Administrator role is required at the subscription level since you'll be performing role assignments to managed identities across various resource groups 
  
- Refer roles here in this [link](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles)

## Tools Installation
- Latest [Azure CLI installed](https://learn.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest) (must be at least 2.40), or you can perform this from Azure Cloud Shell by clicking below.

  [![Launch Azure Cloud Shell](https://learn.microsoft.com/azure/includes/media/cloud-shell-try-it/launchcloudshell.png)](https://shell.azure.com)
- Latest [Terraform tools](https://developer.hashicorp.com/terraform/tutorials/azure-get-started/install-cli)
- PowerShell 7.0, if you would like to use PowerShell to do your Azure Storage Account for Terraform Remote State 

## Terraform Configuration

If you haven't already done so, configure Terraform using one of the following options:

* [Configure Terraform in Azure Cloud Shell with Bash](https://learn.microsoft.com/azure/developer/terraform/get-started-cloud-shell-bash)
* [Configure Terraform in Azure Cloud Shell with PowerShell](https://learn.microsoft.com/azure/developer/terraform/get-started-cloud-shell-powershell)
* [Configure Terraform in Windows with Bash](https://learn.microsoft.com/azure/developer/terraform/get-started-windows-bash)
* [Configure Terraform in Windows with PowerShell](https://learn.microsoft.com/azure/developer/terraform/get-started-windows-powershell)
* [Run the commands using a local devcontainer](https://code.visualstudio.com/docs/devcontainers/containers) using the config provided in this repo's .devcontainer folder

## Configure remote state storage account

Before you use Azure Storage as a backend for the state file, you must create a storage account.
Run the following commands or configuration to create an Azure storage account and container:

Using Azure CLI

```bash
LOCATION="eastus"
RESOURCE_GROUP_NAME="tfstate"
STORAGE_ACCOUNT_NAME="<tfstate unique name>"
CONTAINER_NAME="tfstate"

# Create Resource Group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create Storage Account
az storage account create -n $STORAGE_ACCOUNT_NAME -g $RESOURCE_GROUP_NAME -l $LOCATION --sku Standard_LRS

# Create blob container
az storage container-rm create --storage-account $STORAGE_ACCOUNT_NAME --name $CONTAINER_NAME
```

# Deploy

## Provide parameters required for deployment

[TF Docs: Variable Definitions (.tfvars) Files](https://www.terraform.io/language/values/variables#variable-definitions-tfvars-files)

> [!NOTE]
> If you are using Azure CLI authentication that is not a service principal or OIDC, the [AzureRM provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide) now requires setting the `subscription_id` in the provider. Running the following command in your Bash terminal before moving on to the next commands. 
> 
> `export ARM_SUBSCRIPTION_ID=00000000-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

### Bash shell (i.e. inside WSL2 for windows 11, or any linux-based OS)
``` bash
terraform init `
    --backend-config=resource_group_name="tfstate" `
    --backend-config=storage_account_name=<Your TF State Store Storage Account Name> `
    --backend-config=container_name="tfstate" `
    --backend-config=key="acalza/terraform.state"
terraform plan --var-file terraform.tfvars -out tfplan
terraform apply tfplan
```

## Clean up resources

When you are done exploring the resources created by the Standalone deployment guide, use the following command to remove the resources you created.

```bash
terraform destroy --var-file=terraform.tfvars
```


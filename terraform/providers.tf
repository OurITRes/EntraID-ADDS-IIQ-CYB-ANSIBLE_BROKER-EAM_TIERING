
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.49"
    }
    microsoft365 = {
      source  = "hashicorp/microsoft365"
      version = "~> 0.2"
    }
  }
}
provider "azuread" {}

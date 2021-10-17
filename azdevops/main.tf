// Provider
terraform {
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">=0.1.0"
    }
  }
  backend "s3" { key = "azdevops.main.tfstate" }
}

locals {
  project_id   = data.azuredevops_project.project.id
  app_import   = var.app_repo_input_url == null || var.app_repo_input_url == "" ? false : true
  infra_import = var.infra_repo_input_url == null || var.infra_repo_input_url == "" ? false : true
}
// Refer project
data "azuredevops_project" "project" {
  name = var.project_name
}

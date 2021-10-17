// Create App Repo
resource "azuredevops_git_repository" "app_repo" {
  project_id = local.project_id
  name       = "TheApp"
  initialization {
    init_type   = local.app_import ? "Import" : "Clean"
    source_type = local.app_import ? "Git" : null
    source_url  = local.app_import ? var.app_repo_input_url : null
  }
}

locals {
  app_repo_ci = [
    {
      name     = "User-App CI"
      path     = "\\Service CI"
      yml_path = "user-app/azure-pipelines.yml"
    },
    {
      name     = "User-DB CD"
      path     = "\\Database CD"
      yml_path = "user-app/azure-pipelines-db.yml"
    },
    {
      name     = "Product-App CI"
      path     = "\\Service CI"
      yml_path = "product-app/azure-pipelines.yml"
    },
    {
      name     = "Product-DB CD"
      path     = "\\Database CD"
      yml_path = "product-app/azure-pipelines-db.yml"
    },
  ]
}
// Create User-App CI Pipeline
resource "azuredevops_build_definition" "app_repo_ci" {
  for_each = { for v in local.app_repo_ci : v.name => v }

  project_id = local.project_id
  name       = each.value.name
  path       = each.value.path

  ci_trigger {
    use_yaml = true
  }
  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_git_repository.app_repo.id
    branch_name = azuredevops_git_repository.app_repo.default_branch
    yml_path    = each.value.yml_path
  }
}

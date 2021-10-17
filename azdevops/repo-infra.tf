// Create Infra Repo
resource "azuredevops_git_repository" "infra_repo" {
  project_id = local.project_id
  name       = "TheInfra"
  initialization {
    init_type   = local.infra_import ? "Import" : "Clean"
    source_type = local.infra_import ? "Git" : null
    source_url  = local.infra_import ? var.infra_repo_input_url : null
  }
}

locals {
  infra_repo_cd = [
    {
      name     = "Base CD"
      yml_path = "tools/cd/base-infra-azure-pipelines.yml"
    },
    {
      name     = "Database CD"
      yml_path = "tools/cd/database-azure-pipelines.yml"
    },
    {
      name     = "AZ Agent CD"
      yml_path = "tools/cd/azagent-azure-pipelines.yml"
    },
    {
      name     = "Product Service CD"
      yml_path = "tools/cd/product-service-azure-pipelines.yml"
    },
    {
      name     = "User Service CD"
      yml_path = "tools/cd/user-service-azure-pipelines.yml"
    }
  ]
}

resource "azuredevops_build_definition" "infra_repo_cd" {
  for_each = { for v in local.infra_repo_cd : v.name => v }

  project_id = local.project_id
  name       = each.value.name
  path       = "\\Infra"

  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_git_repository.infra_repo.id
    branch_name = azuredevops_git_repository.infra_repo.default_branch
    yml_path    = each.value.yml_path
  }
}

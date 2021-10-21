resource "azuredevops_agent_pool" "pool" {
  name = "prod-demo-az-agent"
}

resource "azuredevops_agent_queue" "queue" {
  project_id    = data.azuredevops_project.project.id
  agent_pool_id = azuredevops_agent_pool.pool.id
}

# Grant acccess to queue to all pipelines in the project
resource "azuredevops_resource_authorization" "auth" {
  project_id  = data.azuredevops_project.project.id
  resource_id = azuredevops_agent_queue.queue.id
  type        = "queue"
  authorized  = true
}

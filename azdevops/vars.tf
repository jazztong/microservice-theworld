variable "project_name" {
  type        = string
  description = "Fill in your project name, it must match the project name that run this pipeline"
  default     = "Microservice-App"
}

variable "app_repo_input_url" {
  type        = string
  description = "Fill in the input url to import as application repo"
  default     = "https://github.com/jazztong/microservice-theapp.git"
}

variable "infra_repo_input_url" {
  type        = string
  description = "Fill in the input url to import as infrastructure repo"
  default     = "https://github.com/jazztong/microservice-theinfra.git"
}

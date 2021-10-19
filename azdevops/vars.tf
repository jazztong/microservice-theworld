variable "project_name" {
  type = string
  # Fill in your project name
  #default = "<<Fill in your project name>>"
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

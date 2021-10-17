variable "project_name" {
  type = string
  # Fill in your project name
  #default = "<<Fill in your project name>>"
}

variable "app_repo_input_url" {
  type        = string
  description = "Fill in the input url to import as application repo"
  default     = null
}

variable "infra_repo_input_url" {
  type        = string
  description = "Fill in the input url to import as infrastructure repo"
  default     = null
}

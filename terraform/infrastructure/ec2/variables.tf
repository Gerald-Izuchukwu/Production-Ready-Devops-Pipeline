variable "environment" {
  type    = string
  default = "production"
}

variable "app_image" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "security_group_id" {}

variable "alb_target_group_arn" {}

variable "subnet_ids" {}

variable "db_name" {}

variable "db_user" {}
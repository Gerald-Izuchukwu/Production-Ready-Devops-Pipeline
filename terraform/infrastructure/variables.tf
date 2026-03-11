variable "aws_region" {
  type    = string
  default = "us-east-1"
}

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

variable "db_name" {}

variable "db_user" {
  type = string
}
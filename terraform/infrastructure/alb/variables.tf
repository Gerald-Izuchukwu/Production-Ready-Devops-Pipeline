variable "environment" {
  type    = string
  default = "production"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the security groups will be created"
}

variable "domain_name" {
  type        = string
  description = "The domain name for the SSL certificate (e.g., example.com)"

}

variable "alb_security_group_id" {

}

variable "subnet_ids" {

}
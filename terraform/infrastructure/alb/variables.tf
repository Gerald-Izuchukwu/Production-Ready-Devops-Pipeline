variable "environment" {
  type    = string
  default = "production"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the security groups will be created"
}



variable "alb_security_group_id" {

}

variable "subnet_ids" {

}
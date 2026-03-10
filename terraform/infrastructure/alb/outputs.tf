output "alb_dns_name" {
  description = "Access your app at this URL"
  value       = "http://${aws_lb.main.dns_name}"
}
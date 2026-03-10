output "alb_dns_name" {
  description = "Access your app at this URL"
  value       = "http://${aws_lb.main.dns_name}"
}

output "alb_target_group_arn" {
  value = aws_lb_target_group.app.arn
}
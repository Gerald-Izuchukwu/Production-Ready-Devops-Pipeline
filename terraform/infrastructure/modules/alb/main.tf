# # ─────────────────────────────────────────
# # SSL CERTIFICATE (ACM)
# # ─────────────────────────────────────────

# resource "aws_acm_certificate" "app" {
#   domain_name       = var.domain_name
#   validation_method = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = { Name = "${var.environment}-cert" }
# }


# ─────────────────────────────────────────
# APPLICATION LOAD BALANCER
# ─────────────────────────────────────────

resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.subnet_ids

  tags = { Name = "${var.environment}-alb" }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.environment}-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = { Name = "${var.environment}-tg" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
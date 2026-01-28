terraform {
  required_providers {
    aws     = { source = "hashicorp/aws" }
    archive = { source = "hashicorp/archive" }
  }
}

data "aws_vpc" "default" {
  count = var.use_default_vpc ? 1 : 0
  default = true
}

data "aws_subnets" "default_public" {
  count = var.use_default_vpc ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

module "fn" {
  source = "../lambda_fn"

  function_name = var.function_name
  memory_mb     = var.function_memory_mb
  timeout_s     = var.function_timeout_s
}

resource "aws_security_group" "alb" {
  name        = "${var.stack_name_prefix}-alb-sg-${replace(var.region_name, "/[\W_]/", "-")}"
  description = "Allow HTTP inbound"
  vpc_id      = data.aws_vpc.default[0].id

  ingress {
    description = "HTTP"
    protocol    = "tcp"
    from_port   = var.alb_listener_port
    to_port     = var.alb_listener_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "this" {
  name               = "${var.stack_name_prefix}-alb-${replace(var.region_name, "/[\W_]/", "-")}"
  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.alb.id]
  subnets         = data.aws_subnets.default_public[0].ids
}

resource "aws_lb_target_group" "lambda" {
  name        = "${var.stack_name_prefix}-tg-${replace(var.region_name, "/[\W_]/", "-")}"
  target_type = "lambda"
}

resource "aws_lb_target_group_attachment" "lambda" {
  target_group_arn = aws_lb_target_group.lambda.arn
  target_id        = module.fn.lambda_arn
}

resource "aws_lambda_permission" "alb_invoke" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = module.fn.lambda_arn
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.lambda.arn
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.alb_listener_port
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      status_code  = "404"
      content_type = "text/plain"
      message_body = "Not Found"
    }
  }
}

resource "aws_lb_listener_rule" "path" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  condition {
    path_pattern {
      values = [var.alb_path]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lambda.arn
  }
}

output "alb_dns_name" { value = aws_lb.this.dns_name }
output "lambda_arn"   { value = module.fn.lambda_arn }

terraform {
  required_providers {
    aws     = { source = "hashicorp/aws" }
    archive = { source = "hashicorp/archive" }
  }
}

# Get availability zones for the region
data "aws_availability_zones" "available" {
  count = var.use_default_vpc ? 1 : 0
  state = "available"
}

# Create VPC (will be used if default VPC doesn't exist)
resource "aws_vpc" "main" {
  count                = var.use_default_vpc ? 1 : 0
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.stack_name_prefix}-vpc-${replace(var.region_name, "/[^a-zA-Z0-9-]/", "-")}"
  }
}

# Create internet gateway for the VPC
resource "aws_internet_gateway" "main" {
  count  = var.use_default_vpc ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  tags = {
    Name = "${var.stack_name_prefix}-igw-${replace(var.region_name, "/[^a-zA-Z0-9-]/", "-")}"
  }
}

# Create public subnets
resource "aws_subnet" "public" {
  count                   = var.use_default_vpc ? min(2, length(data.aws_availability_zones.available[0].names)) : 0
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available[0].names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.stack_name_prefix}-public-subnet-${count.index + 1}-${replace(var.region_name, "/[^a-zA-Z0-9-]/", "-")}"
  }
}

# Create route table for public subnets
resource "aws_route_table" "public" {
  count  = var.use_default_vpc ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = {
    Name = "${var.stack_name_prefix}-public-rt-${replace(var.region_name, "/[^a-zA-Z0-9-]/", "-")}"
  }
}

# Associate route table with public subnets
resource "aws_route_table_association" "public" {
  count          = var.use_default_vpc ? length(aws_subnet.public) : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

locals {
  vpc_id     = var.use_default_vpc ? aws_vpc.main[0].id : null
  subnet_ids = var.use_default_vpc ? aws_subnet.public[*].id : []
  alb_port   = coalesce(var.alb_listener_port, 80)
}

module "fn" {
  source = "../lambda_fn"

  function_name = var.function_name
  memory_mb     = var.function_memory_mb
  timeout_s     = var.function_timeout_s
}

resource "aws_security_group" "alb" {
  name        = "${var.stack_name_prefix}-alb-sg-${replace(var.region_name, "/[^a-zA-Z0-9-]/", "-")}"
  description = "Allow HTTP inbound"
  vpc_id      = local.vpc_id

  tags = {
    Name = "${var.stack_name_prefix}-alb-sg-${replace(var.region_name, "/[^a-zA-Z0-9-]/", "-")}"
  }
}

resource "aws_security_group_rule" "alb_ingress" {
  type              = "ingress"
  description       = "HTTP"
  from_port         = local.alb_port
  to_port           = local.alb_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  description       = "Allow all outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_lb" "this" {
  name               = "${var.stack_name_prefix}-alb-${replace(var.region_name, "/[^a-zA-Z0-9-]/", "-")}"
  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.alb.id]
  subnets         = local.subnet_ids
}

resource "aws_lb_target_group" "lambda" {
  name        = "${var.stack_name_prefix}-tg-${replace(var.region_name, "/[^a-zA-Z0-9-]/", "-")}"
  target_type = "lambda"
}

# Lambda permission must be created BEFORE target group attachment
resource "aws_lambda_permission" "alb_invoke" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = module.fn.lambda_arn
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.lambda.arn
}

resource "aws_lb_target_group_attachment" "lambda" {
  target_group_arn = aws_lb_target_group.lambda.arn
  target_id        = module.fn.lambda_arn

  depends_on = [aws_lambda_permission.alb_invoke]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = local.alb_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
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
output "lambda_arn" { value = module.fn.lambda_arn }

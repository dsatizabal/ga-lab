resource "aws_globalaccelerator_accelerator" "ga" {
  name            = "sap02-ga"
  ip_address_type = "IPV4"
  enabled         = true
}

resource "aws_globalaccelerator_listener" "ga_tcp" {
  accelerator_arn = aws_globalaccelerator_accelerator.ga.id
  protocol        = "TCP"

  port_range {
    from_port = var.ga_listener_port
    to_port   = var.ga_listener_port
  }

  client_affinity = "NONE"
}

# One endpoint group per region, pointing to that region's ALB ARN.
resource "aws_globalaccelerator_endpoint_group" "ga_endpoints" {
  for_each = var.ga_endpoints

  listener_arn          = aws_globalaccelerator_listener.ga_tcp.id
  endpoint_group_region = each.key

  traffic_dial_percentage = 100

  # Health checks for ALB endpoints can be HTTP.
  health_check_protocol = "HTTP"
  health_check_port     = 80
  health_check_path     = var.ga_health_check_path

  health_check_interval_seconds = 30
  threshold_count               = 3

  endpoint_configuration {
    endpoint_id = each.value.alb_arn
    weight      = 128
  }
}

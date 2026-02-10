variable "ga_listener_port" {
  description = "GA listener port (TCP)"
  type        = number
  default     = 80
}

variable "ga_health_check_path" {
  description = "Health check path GA uses when protocol is HTTP"
  type        = string
  default     = "/"
}

variable "ga_endpoints" {
  description = "Map of region to ALB ARN for GA endpoint groups"
  type = map(
    object({
      alb_arn = string
    })
  )
  default = {}
}

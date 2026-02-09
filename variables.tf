variable "aws_access_key_id" {
  type        = string
  description = "AWS Access Key ID"
  sensitive   = true
}

variable "aws_secret_access_key" {
  type        = string
  description = "AWS Secret Access Key"
  sensitive   = true
}

variable "stack_name_prefix" {
  type        = string
  description = "Prefix for named resources"
  default     = "ga-lab"
}

variable "regions" {
  description = <<EOT
Map of regions to deploy in. Keys are AWS region names.
Values can override settings like:
{
  "lambda_memory_mb": 256,
  "lambda_timeout_s": 5,
  "alb_listener_port": 80,
  "alb_path": "/ga"
}
EOT
  type = map(object({
    lambda_memory_mb  = optional(number)
    lambda_timeout_s  = optional(number)
    alb_listener_port = optional(number)
    alb_path          = optional(string)
  }))
}

variable "function_name" {
  type = string
}

variable "memory_mb" {
  type    = number
  default = 256
}

variable "timeout_s" {
  type    = number
  default = 5
}

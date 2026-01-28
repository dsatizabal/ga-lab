variable "region_name"       { type = string }
variable "stack_name_prefix" { type = string }
variable "function_name"     { type = string }

variable "function_memory_mb" { type = number, default = 256 }
variable "function_timeout_s" { type = number, default = 5 }

variable "alb_listener_port" { type = number, default = 80 }
variable "alb_path"          { type = string,  default = "/ga" }

variable "use_default_vpc"   { type = bool, default = true }

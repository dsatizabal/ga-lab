terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4"
    }
  }
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "euw1"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "apse1"
  region = "ap-southeast-1"
}

locals {
  provider_by_region = {
    "us-east-1"      = aws.use1
    "eu-west-1"      = aws.euw1
    "ap-southeast-1" = aws.apse1
  }
}

locals {
  region_keys = keys(var.regions)
}

module "regional_stack" {
  for_each = var.regions

  providers = {
    aws = local.provider_by_region[each.key]
  }

  source = "./modules/alb_lambda"

  region_name         = each.key
  stack_name_prefix   = var.stack_name_prefix
  function_name       = "${var.stack_name_prefix}-hello-${replace(each.key, "/[\W_]/", "-")}"
  function_memory_mb  = lookup(each.value, "lambda_memory_mb", 256)
  function_timeout_s  = lookup(each.value, "lambda_timeout_s", 5)

  alb_listener_port   = lookup(each.value, "alb_listener_port", 80)
  alb_path            = lookup(each.value, "alb_path", "/ga")
  use_default_vpc     = true
}

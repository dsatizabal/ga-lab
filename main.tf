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
  alias                   = "use1"
  region                  = "us-east-1"
  access_key              = var.aws_access_key_id
  secret_key              = var.aws_secret_access_key
}

provider "aws" {
  alias                   = "euw1"
  region                  = "eu-west-1"
  access_key              = var.aws_access_key_id
  secret_key              = var.aws_secret_access_key
}

provider "aws" {
  alias                   = "apse1"
  region                  = "ap-southeast-1"
  access_key              = var.aws_access_key_id
  secret_key              = var.aws_secret_access_key
}

module "regional_stack_use1" {
  count = contains(keys(var.regions), "us-east-1") ? 1 : 0

  source = "./modules/alb_lambda"

  providers = {
    aws = aws.use1
  }

  region_name        = "us-east-1"
  stack_name_prefix  = var.stack_name_prefix
  function_name      = "${var.stack_name_prefix}-hello-us-east-1"
  function_memory_mb = lookup(var.regions["us-east-1"], "lambda_memory_mb", 256)
  function_timeout_s = lookup(var.regions["us-east-1"], "lambda_timeout_s", 5)

  alb_listener_port = lookup(var.regions["us-east-1"], "alb_listener_port", 80)
  alb_path          = lookup(var.regions["us-east-1"], "alb_path", "/ga")
  use_default_vpc   = true
}

module "regional_stack_euw1" {
  count = contains(keys(var.regions), "eu-west-1") ? 1 : 0

  source = "./modules/alb_lambda"

  providers = {
    aws = aws.euw1
  }

  region_name        = "eu-west-1"
  stack_name_prefix  = var.stack_name_prefix
  function_name      = "${var.stack_name_prefix}-hello-eu-west-1"
  function_memory_mb = lookup(var.regions["eu-west-1"], "lambda_memory_mb", 256)
  function_timeout_s = lookup(var.regions["eu-west-1"], "lambda_timeout_s", 5)

  alb_listener_port = lookup(var.regions["eu-west-1"], "alb_listener_port", 80)
  alb_path          = lookup(var.regions["eu-west-1"], "alb_path", "/ga")
  use_default_vpc   = true
}

module "regional_stack_apse1" {
  count = contains(keys(var.regions), "ap-southeast-1") ? 1 : 0

  source = "./modules/alb_lambda"

  providers = {
    aws = aws.apse1
  }

  region_name        = "ap-southeast-1"
  stack_name_prefix  = var.stack_name_prefix
  function_name      = "${var.stack_name_prefix}-hello-ap-southeast-1"
  function_memory_mb = lookup(var.regions["ap-southeast-1"], "lambda_memory_mb", 256)
  function_timeout_s = lookup(var.regions["ap-southeast-1"], "lambda_timeout_s", 5)

  alb_listener_port = lookup(var.regions["ap-southeast-1"], "alb_listener_port", 80)
  alb_path          = lookup(var.regions["ap-southeast-1"], "alb_path", "/ga")
  use_default_vpc   = true
}

locals {
  regional_stacks = merge(
    length(module.regional_stack_use1) > 0 ? { "us-east-1" = module.regional_stack_use1[0] } : {},
    length(module.regional_stack_euw1) > 0 ? { "eu-west-1" = module.regional_stack_euw1[0] } : {},
    length(module.regional_stack_apse1) > 0 ? { "ap-southeast-1" = module.regional_stack_apse1[0] } : {}
  )
}

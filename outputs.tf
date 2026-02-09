output "alb_dns_by_region" {
  value = {
    for r, m in local.regional_stacks : r => m.alb_dns_name
  }
}

output "lambda_arn_by_region" {
  value = {
    for r, m in local.regional_stacks : r => m.lambda_arn
  }
}

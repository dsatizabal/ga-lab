output "alb_dns_by_region" {
  value = {
    for r, m in module.regional_stack : r => m.alb_dns_name
  }
}

output "lambda_arn_by_region" {
  value = {
    for r, m in module.regional_stack : r => m.lambda_arn
  }
}

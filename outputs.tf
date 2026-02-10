output "alb_dns_by_region" {
  description = "ALB DNS names by region"
  value = {
    for r, m in local.regional_stacks : r => m.alb_dns_name
  }
}

output "lambda_arn_by_region" {
  description = "Lambda function ARNs by region"
  value = {
    for r, m in local.regional_stacks : r => m.lambda_arn
  }
}

output "global_accelerator_dns_name" {
  description = "Global Accelerator DNS name (use this to access the application globally)"
  value       = length(module.global_accelerator) > 0 ? module.global_accelerator[0].global_accelerator_dns_name : null
}

output "global_accelerator_ip_addresses" {
  description = "Global Accelerator static Anycast IPv4 addresses (2 IPs)"
  value       = length(module.global_accelerator) > 0 ? module.global_accelerator[0].global_accelerator_ip_addresses : null
}

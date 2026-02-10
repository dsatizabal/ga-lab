output "global_accelerator_dns_name" {
  description = "GA DNS name (use directly or point Route53 alias to it)"
  value       = aws_globalaccelerator_accelerator.ga.dns_name
}

output "global_accelerator_ip_addresses" {
  description = "Two static Anycast IPv4 addresses for the accelerator"
  value       = aws_globalaccelerator_accelerator.ga.ip_sets[0].ip_addresses
}

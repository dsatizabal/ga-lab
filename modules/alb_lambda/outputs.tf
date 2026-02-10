output "alb_arn" {
  description = "ARN of the ALB (used by Global Accelerator endpoint groups)"
  value       = aws_lb.this.arn
}

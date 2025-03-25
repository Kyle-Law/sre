output "aws_lb_controller_sa_name" {
  description = "Name of the AWS Load Balancer Controller Service Account"
  value       = kubernetes_service_account.aws_lb_controller_sa.metadata[0].name
}

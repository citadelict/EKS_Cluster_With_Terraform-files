output "ebs_csi_iam_role_arn" {
  description = "IAM role arn of ebs csi"
  value       = module.ebs_csi_eks_role.iam_role_arn
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks_cluster.cluster_name}"
}

# Output the DNS record details
# output "dns_record" {
#   value = aws_route53_record.ingress_nginx
# }

# output "load_balancer_hostname" {
#   value = data.kubernetes_service.ingress_nginx.status.0.load_balancer.0.ingress.0.hostname
# }
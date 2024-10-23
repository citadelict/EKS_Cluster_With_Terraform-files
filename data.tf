# get all available AZs in our region
data "aws_availability_zones" "available_azs" {
  state = "available"
}
data "aws_caller_identity" "current" {} # used for accesing Account ID and ARN

# get EKS cluster info to configure Kubernetes and Helm providers
data "aws_eks_cluster" "cluster" {
  name = module.eks_cluster.cluster_id
}
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_id
}

data "aws_partition" "current_testing" {}

data "aws_caller_identity" "current_testing" {}

data "aws_eks_cluster" "cluster_testing" {
  name = module.eks_cluster.cluster_name
  depends_on = [module.eks_cluster]
}

# Get the ELB hosted zone ID
data "aws_elb_hosted_zone_id" "main" {}



# Data source to get the Nginx Ingress Controller's LoadBalancer hostname
data "kubernetes_service" "ingress_nginx" {
  depends_on = [helm_release.ingress_nginx_webhook]

  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
}

data "kubernetes_service" "nginx_ingress_loadbalancer" {
  metadata {
    name      = "ingress-nginx-controller" # Ensure this matches the actual name of your Nginx service
    namespace = "ingress-nginx"
  }
}


data "aws_route53_zone" "citatech_online" {
  name         = "citatech.online" # Replace with your actual domain name
  private_zone = false             # Set to true if it's a private hosted zone
}

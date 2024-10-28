
# get all available AZs in our region
data "aws_availability_zones" "available_azs" {
  state = "available"
}
data "aws_caller_identity" "current" {} # used for accesing Account ID and ARN

# get EKS cluster info to configure Kubernetes and Helm providers

data "aws_eks_cluster" "cluster" {
  name = module.eks_cluster.cluster_name
  depends_on = [
        module.eks_cluster,
        null_resource.update_kubeconfig  # Adding this for extra safety
    ]
}
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_name
}

data "aws_partition" "current_testing" {}

data "aws_caller_identity" "current_testing" {}

data "aws_eks_cluster" "cluster_testing" {
  name = module.eks_cluster.cluster_name
  depends_on = [module.eks_cluster]
}

data "aws_eks_addon_version" "this" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = module.eks_cluster.cluster_version
  most_recent        = true
}

# Get DNS name of the ELB created by the Ingress Controller.

data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx"  # Adjust this if your service name is different
    namespace = "ingress-nginx"             # Ensure this matches the namespace used for nginx-ingress
  }
  depends_on = [helm_release.ingress-nginx]

}




# data "aws_lb" "ingress_nginx" {
#   name = data.kubernetes_service.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname
# }

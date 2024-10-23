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
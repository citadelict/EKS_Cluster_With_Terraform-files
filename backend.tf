terraform {
  backend "s3" {
    bucket = "citatech-eks-terraform-state1"
    key    = "eks/terraform.tfstate"
    region = "us-west-1"
    # dynamodb_table = "eks-cluster-lock"
    encrypt = true
  }
}

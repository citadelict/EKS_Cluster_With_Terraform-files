terraform {
  backend "s3" {
    bucket = "citatech-eks-tf-state-unique-12345"
    key    = "eks/terraform.tfstate"
    region = "us-west-1"
    # dynamodb_table = "eks-cluster-lock"
    encrypt = true
  }
}

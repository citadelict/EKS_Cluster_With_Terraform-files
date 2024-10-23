module "eks_cluster" {
  source       = "terraform-aws-modules/eks/aws"
  version      = "~> 18.0"
  cluster_name = var.cluster_name
  # cluster_version                 = "1.22"
  cluster_version                 = "1.25"
  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # Self Managed Node Group(s)
  self_managed_node_group_defaults = {
    instance_type                          = var.asg_instance_types[0]
    update_launch_template_default_version = true
  }
  self_managed_node_groups = local.self_managed_node_groups

  # aws-auth configmap
  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true
  aws_auth_users            = concat(local.admin_user_map_users, local.developer_user_map_users)
  tags = {
    Environment = "prod"
    Terraform   = "true"
  }
}

# Attach AmazonEKSWorkerNodePolicy for EKS operations to all self-managed node groups
resource "aws_iam_policy_attachment" "self_managed_node_policy_attachment" {
  for_each   = toset(local.node_group_roles)
  name       = "attach-self-managed-node-policies-${each.key}"
  roles      = [each.key]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Attach AmazonEC2ContainerRegistryReadOnly for ECR access to all self-managed node groups
resource "aws_iam_policy_attachment" "self_managed_node_ecr_policy_attachment" {
  for_each   = toset(local.node_group_roles)
  name       = "attach-self-managed-node-ecr-policy-${each.key}"
  roles      = [each.key]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Create a custom policy for EBS management
resource "aws_iam_policy" "self_managed_ebs_policy" {
  name   = "SelfManagedEBSPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
        "ec2:CreateVolume",
        "ec2:DescribeVolumes",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:DeleteVolume",
        "ec2:DescribeVolumeStatus",
        "ec2:DescribeSnapshots",
        "ec2:CreateSnapshot",
        "ec2:DeleteSnapshot",
        "ec2:CreateTags"
        ]
        Resource = "*"
      },
    ]
  })
}

# Attach the custom EBS policy dynamically to all self-managed node IAM roles
resource "aws_iam_policy_attachment" "self_managed_ebs_policy_attachment" {
  for_each   = toset(local.node_group_roles)
  name       = "attach-self-managed-ebs-policy-${each.key}"
  roles      = [each.key]
  policy_arn = aws_iam_policy.self_managed_ebs_policy.arn
}

###################
# EBS CSI Role    #
###################

module "ebs_csi_eks_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "ebs-csi-driver-role"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = local.oidc_provider_name
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

# Attach the AmazonEBSCSIDriverPolicy to the IAM role
resource "aws_iam_policy_attachment" "ebs_csi_driver_policy_attachment" {
  name       = "attach-ebs-csi-driver-policy"
  roles      = [module.ebs_csi_eks_role.iam_role_name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}




###################
# Storage Classes #
###################

resource "kubernetes_storage_class_v1" "storageclass_gp2" {
  depends_on = [
    module.eks_cluster,
    aws_iam_policy_attachment.ebs_csi_driver_policy_attachment
  ]
  metadata {
    name = "gp2-encrypted"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    type      = "gp2"
    encrypted = "true"
  }
}

resource "null_resource" "set_kubeconfig_env" {
  depends_on = [module.eks_cluster]

  provisioner "local-exec" {
    command = <<EOT
      if ! grep -Fxq "export KUBECONFIG=${path.module}/kubeconfig" ~/.bashrc; then
        echo "export KUBECONFIG=${path.module}/kubeconfig" >> ~/.bashrc
      fi
    EOT
    interpreter = ["bash", "-c"]
  }

  # Triggers to ensure this runs whenever the kubeconfig path or cluster name changes
  triggers = {
    kubeconfig_path = "${path.module}/kubeconfig"
    cluster_name    = module.eks_cluster.cluster_name
  }
}

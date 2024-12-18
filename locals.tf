locals {
  partition          = data.aws_partition.current_testing.id
  account_id         = data.aws_caller_identity.current_testing.account_id
  oidc_provider_arn  = replace(data.aws_eks_cluster.cluster_testing.identity[0].oidc[0].issuer, "https://", "")
  oidc_provider_name = "arn:${local.partition}:iam::${local.account_id}:oidc-provider/${local.oidc_provider_arn}"
  
  admin_user_map_users = [
    for admin_user in var.admin_users : {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${admin_user}"
      username = admin_user
      groups   = ["system:masters"]
    }
  ]
  
  developer_user_map_users = [
    for developer_user in var.developer_users : {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${developer_user}"
      username = developer_user
      groups   = ["${var.name_prefix}-developers"]
    }
  ]

 self_managed_node_groups = {
  worker_group1 = {
    name = "${var.cluster_name}-wg"

    min_size      = var.autoscaling_minimum_size_by_az * length(data.aws_availability_zones.available_azs.zone_ids)
    desired_size  = var.autoscaling_minimum_size_by_az * length(data.aws_availability_zones.available_azs.zone_ids)
    max_size      = var.autoscaling_maximum_size_by_az * length(data.aws_availability_zones.available_azs.zone_ids)
    instance_type = var.asg_instance_types[0].instance_type
    
    bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          delete_on_termination = true
          encrypted             = false
          volume_size           = 10
          volume_type           = "gp2"
        }
      }
    }
    use_mixed_instances_policy = true
    mixed_instances_policy = {
      instances_distribution = {
        spot_instance_pools = 4
      }
      override = var.asg_instance_types
    }
  }
}


}

locals {
  ingress_lb_hostname = try(data.kubernetes_service.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname, null)
}

locals {
  oidc_provider = replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")
}
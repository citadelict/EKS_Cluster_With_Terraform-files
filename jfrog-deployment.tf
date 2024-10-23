# Create namespace
resource "kubernetes_namespace" "tools" {
  metadata {
    name = "tools"
    labels = {
      name = "tools"
    }
  }
}


resource "aws_security_group_rule" "allow_postgres_access" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = module.eks_cluster.node_security_group_id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow PostgreSQL access for Artifactory"
}

resource "aws_security_group_rule" "allow_artifactory_http_https" {
  type              = "ingress"
  from_port         = 8081
  to_port           = 8082
  protocol          = "tcp"
  security_group_id = module.eks_cluster.node_security_group_id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP/HTTPS access for Artifactory"
}

resource "aws_security_group_rule" "allow_nginx_access" {
  type              = "ingress"
  from_port         = 80
  to_port           = 443
  protocol          = "tcp"
  security_group_id = module.eks_cluster.node_security_group_id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow Nginx HTTP and HTTPS access"
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = module.eks_cluster.node_security_group_id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic from EKS worker nodes"
}

# Helm release for Artifactory
resource "helm_release" "artifactory" {
  name       = "artifactory"
  repository = "https://charts.jfrog.io"
  chart      = "artifactory"
  version    = "107.90.10"
  namespace  = kubernetes_namespace.tools.metadata[0].name

  values = [
    file("${path.module}/values.yaml")
  ]

  depends_on = [
    kubernetes_namespace.tools
  ]
}





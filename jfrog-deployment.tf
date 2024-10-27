# Create namespace
resource "kubernetes_namespace" "tools" {
  metadata {
    name = "tools"
    labels = {
      name = "tools"
    }
  }
}


# Helm Release for Artifactory
resource "helm_release" "artifactory" {
  name       = "artifactory"
  repository = "https://charts.jfrog.io"
  chart      = "artifactory"
  version    = "107.90.10"
  namespace  = kubernetes_namespace.tools.metadata[0].name

  values = [
    file("${path.module}/values.yaml")
  ]

  timeout = 600 # Timeout in seconds (10 minutes)

  depends_on = [
    kubernetes_namespace.tools,
    null_resource.update_kubeconfig  # Ensure kubeconfig is updated first
  ]
}





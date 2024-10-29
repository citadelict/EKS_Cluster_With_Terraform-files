resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "ingress-nginx" {
  name       = "ingress-nginx"
  # repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "./nginx-ingress-chart/ingress-nginx"

  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name
  timeout = 600

  depends_on = [
    module.eks_cluster,
    kubernetes_namespace.ingress_nginx,
    helm_release.artifactory
  ]
  

  values = [
    "${file("values.yaml")}"
  ]

  wait   = true  
  atomic = true  

  set {
    name  = "controller.admissionWebhooks.enabled"
    value = "true"
  }
   set {
    name  = "metrics.enabled"
    value = "true"
  }


}

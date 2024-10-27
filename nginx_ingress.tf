resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "ingress-nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name
  timeout = 600

  values = [
    "${file("./nginx-ingress.yaml")}"
  ]

  wait   = true  # Wait until the deployment is complete
  atomic = true  # Roll back on failure

  set {
    name  = "controller.admissionWebhooks.enabled"
    value = "true"
  }
   set {
    name  = "metrics.enabled"
    value = "true"
  }

  set {
    name  = "metrics.enabled"
    value = "true"
  }


  

}



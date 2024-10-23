# First Helm upgrade/install command for ingress-nginx
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  # Force creation of namespace
  set {
    name  = "createNamespace"
    value = "true"
  }
}

# Wait for ingress controller pod to be ready using null_resource
resource "null_resource" "wait_for_ingress" {
  depends_on = [helm_release.ingress_nginx]

  provisioner "local-exec" {
    command = <<EOT
      kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=120s
    EOT
  }
}

# Second Helm upgrade command to enable admission webhooks
resource "helm_release" "ingress_nginx_webhook" {
  depends_on = [null_resource.wait_for_ingress]
  
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"

  set {
    name  = "controller.admissionWebhooks.enabled"
    value = "true"
  }
}

# Create the Artifactory ingress
resource "kubernetes_ingress_v1" "artifactory_ingress" {
  depends_on = [helm_release.ingress_nginx_webhook]

  metadata {
    name      = "artifactory"
    namespace = "tools"
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "tooling.artifactory.sandbox.svc.darey.io"  # Replace with your domain
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "artifactory"
              port {
                number = 8082
              }
            }
          }
        }
      }
    }
  }
}

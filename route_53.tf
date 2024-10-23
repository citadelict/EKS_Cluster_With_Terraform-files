resource "aws_route53_record" "artifactory" {
  depends_on = [kubernetes_ingress_v1.artifactory_ingress]
  
  zone_id = var.hosted_zone_id
  name    = "tooling.artifactory.sandbox.svc.darey.io" # Replace with your domain
  type    = "A"

  alias {
    name                   = data.kubernetes_service.ingress_nginx.status.0.load_balancer.0.ingress.0.hostname
    zone_id               = data.aws_elb_hosted_zone_id.main.id
    evaluate_target_health = true
  }
}

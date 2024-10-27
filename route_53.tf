resource "aws_route53_zone" "ingress_nginx" {
  name = var.your_domain_name
}


resource "aws_route53_record" "nlb" {
  allow_overwrite = true
  zone_id         = aws_route53_zone.ingress_nginx.zone_id
  name            = var.subdomain  # Define the desired subdomain
  type            = "A"

  alias {
    name                   = data.kubernetes_service.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb.ingress_nginx.zone_id  # Use the ELB’s zone ID
    evaluate_target_health = false
  }
}
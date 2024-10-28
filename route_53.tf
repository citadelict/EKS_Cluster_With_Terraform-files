resource "aws_route53_record" "ingress_nginx" {
  count   = local.ingress_lb_hostname != null ? 1 : 0
  zone_id = data.aws_route53_zone.selected.zone_id           
  name    = "tooling-artifactory.citatech.online"  
  type    = "A"                          

  # If using an IP, set it like this
  # records = [data.kubernetes_service.nginx_ingress_lb.status[0].load_balancer[0].ingress[0].ip]

 
  records = [data.kubernetes_service.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname]
}
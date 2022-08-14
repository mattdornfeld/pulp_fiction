resource "aws_route53_zone" "pulp_fiction_milkshake_domain" {
  name = "pulpfictionmilkshake.com"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53domains_registered_domain" "pulp_fiction_milkshake_domain" {
  domain_name = aws_route53_zone.pulp_fiction_milkshake_domain.name

  dynamic "name_server" {
    for_each = sort(toset(aws_route53_zone.pulp_fiction_milkshake_domain.name_servers))

    content {
      name = name_server.value
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_acm_certificate" "pulp_fiction_milkshake_domain" {
  domain_name       = aws_route53_zone.pulp_fiction_milkshake_domain.name
  validation_method = "DNS"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "pulp_fiction_milkshake_domain_validation" {
  for_each = {
    for dvo in aws_acm_certificate.pulp_fiction_milkshake_domain.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.pulp_fiction_milkshake_domain.zone_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_acm_certificate_validation" "pulp_fiction_milkshake_domain_validation" {
  certificate_arn         = aws_acm_certificate.pulp_fiction_milkshake_domain.arn
  validation_record_fqdns = [for record in aws_route53_record.pulp_fiction_milkshake_domain_validation : record.fqdn]

  lifecycle {
    prevent_destroy = true
  }
}

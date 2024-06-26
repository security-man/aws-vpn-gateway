data "local_sensitive_file" "private_cvpn_ca_private_key" {
  filename = ("${path.root}/pki/cvpn.ca.private.key.pem")
}

data "tls_certificate" "private_cvpn_ca_certificate" {
  content = file("${path.root}/pki/cvpn.ca.crt.pem")
}

data "tls_certificate" "private_cvpn_ca_chain_certificate" {
  content = file("${path.root}/pki/cvpn.ca.crt.chain.pem")
}

resource "aws_acm_certificate" "private_cvpn_ca_certificate" {
  private_key       = data.local_sensitive_file.private_cvpn_ca_private_key.content
  certificate_body  = data.tls_certificate.private_cvpn_ca_certificate.content
  certificate_chain = data.tls_certificate.private_cvpn_ca_chain_certificate.content

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ssm_parameter" "private_cvpn_ca_private_key" {
  name  = "private_cvpn_ca_private_key"
  tier  = "Intelligent-Tiering"
  value = data.local_sensitive_file.private_cvpn_ca_private_key.content
  type  = "SecureString"
}

resource "aws_ssm_parameter" "private_cvpn_ca_certificate" {
  name  = "private_cvpn_ca_certificate"
  tier  = "Intelligent-Tiering"
  value = data.tls_certificate.private_cvpn_ca_certificate.content
  type  = "SecureString"
}

resource "aws_ssm_parameter" "private_cvpn_ca_chain_certificate" {
  name  = "private_cvpn_ca_chain_certificate"
  tier  = "Intelligent-Tiering"
  value = data.tls_certificate.private_cvpn_ca_chain_certificate.content
  type  = "SecureString"
}

data "local_sensitive_file" "private_cvpn_server_private_key" {
  filename = ("${path.root}/pki/cvpn-server.private.key.pem")
}

data "tls_certificate" "private_cvpn_server_certificate" {
  content = file("${path.root}/pki/cvpn-server.crt.pem")
}

data "tls_certificate" "private_cvpn_server_chain_certificate" {
  content = file("${path.root}/pki/cvpn-server.crt.chain.pem")
}

resource "aws_acm_certificate" "private_cvpn_server_certificate" {
  private_key       = data.local_sensitive_file.private_cvpn_server_private_key.content
  certificate_body  = data.tls_certificate.private_cvpn_server_certificate.content
  certificate_chain = data.tls_certificate.private_cvpn_server_chain_certificate.content

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "cvpn_log_group" {
  name = "CVPN_Log_Group"
}

resource "aws_cloudwatch_log_stream" "cvpn_log_stream" {
  name           = "CVPN_Log_Stream"
  log_group_name = aws_cloudwatch_log_group.cvpn_log_group.name
}

resource "aws_ec2_client_vpn_endpoint" "cvpn" {
  description            = "terraform-clientvpn-gateway"
  vpc_id                 = var.vpc_id
  client_cidr_block      = var.client_cidr_block
  split_tunnel           = false
  server_certificate_arn = aws_acm_certificate.private_cvpn_server_certificate.arn

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.private_cvpn_ca_certificate.arn
  }

  self_service_portal = "disabled"

  security_group_ids = [aws_security_group.cvpn_sg.id]

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.cvpn_log_group.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.cvpn_log_stream.name
  }
}

resource "local_file" "cvpn_id" {
  content  = aws_ec2_client_vpn_endpoint.cvpn.id
  filename = "cvpn_id"
}

resource "aws_ec2_client_vpn_network_association" "cvpn" {
  count                  = 1
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.cvpn.id
  subnet_id              = var.private_subnet_id

  # relates to https://github.com/hashicorp/terraform-provider-aws/issues/14717
  lifecycle {
    ignore_changes = [subnet_id]
  }
}

resource "aws_ec2_client_vpn_route" "cvpn_internet_route" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.cvpn.id
  destination_cidr_block = "0.0.0.0/0"
  target_vpc_subnet_id   = var.private_subnet_id
}

resource "aws_ec2_client_vpn_authorization_rule" "cvpn_authorisation" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.cvpn.id
  target_network_cidr    = "0.0.0.0/0"
  authorize_all_groups   = true
}

resource "aws_security_group" "cvpn_sg" {
  name        = "allow_tls_udp"
  description = "allow udp inbound port 443 for cvpn"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_udp" {
  security_group_id = aws_security_group.cvpn_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "udp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.cvpn_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  ip_protocol       = -1
  to_port           = -1
}
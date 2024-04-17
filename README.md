# aws-vpn-gateway
A simple vpn gateway to allow remote access to services via a defined egress IP

## Description

This simple repository contains some terraform code and scripts to deploy a handful of AWS resources to form a VPN gateway. The basic architecture is illustrated below:

![alt text](https://github.com/security-man/aws-vpn-gateway/blob/main/AWS_VPN_Gateway_-_AWS_Components.png?raw=true)

## Resources

The terraform code creates the following primary components:

- VPC with a public / private subnet
- NAT gateway associated with the public subnet and static elastic IP
- Route table with routes from private subnet outbound via NAT gateway
- VPC Client VPN gateway
- Route propagation from VPN gateway to VPC private subnet

This set of resources also requires the following pre-requisites:

- Public Key Infrastructure (generating Server X.509 certificate and private key)
- Server X.509 certificate and private key (uploaded to CertificateManager)
- Client X.509 certificate and private key (used to create client Open VPN config file)

## PKI generation

The terraform/pki subdirectory contains 2 bash scripts which generate the necessary pki pre-requisites.

# generate-pki.sh

This uses simple openssl commands and creates a root CA, intermediate CA, and VPN CA. These rely on RSA keys that are then signed via signing-requests made to the acting CA in the chain of trust. Finally, a server X.509 certificate and private key are generated and signed by the VPN CA:

![alt text](https://github.com/security-man/aws-vpn-gateway/blob/main/AWS_VPN_Gateway_-_generate-pki.sh.png?raw=true)

# generate-client.sh

This uses simple openssl commands and creates a client X.509 certificate and private key. The certificate is signed using the pre-existing VPN CA that was generated using generate-pki.sh. generate-client.sh can be executed multiple times with different client names to create multiple client certificates for multiple users:

![alt text](https://github.com/security-man/aws-vpn-gateway/blob/main/AWS_VPN_Gateway_-_generate-client.sh.png?raw=true)

## How to use this repository

- execute generate-pki.sh in the terraform/pki sub-directory
- execute terraform plan/apply to create AWS resources
- execute generate-client.sh in the terraform/pki sub-directory
- execute configure-client-vpn-config.py python file to generate client .ovpn config file
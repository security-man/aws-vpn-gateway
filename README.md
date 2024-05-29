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
- VPC Client VPN gateway, with connection logging to a CloudWatch Log Group
- Route propagation from VPN gateway to VPC private subnet

This set of resources also requires the following pre-requisites (connections rely on mutual-TLS):

- Public Key Infrastructure (including an X.509 certificate and private key for the 'Certificate Authority', used to sign 'server' and 'client' certificates)
- Server X.509 certificate and private key (uploaded to CertificateManager)
- Client X.509 certificate and private key (used to create client Open VPN config file)

## PKI generation

The terraform/pki subdirectory contains a bash script which generates the necessary pki pre-requisites.

# generate-pki.sh

This uses simple openssl commands and creates a root CA, intermediate CA, and VPN CA. These rely on RSA keys that are then signed via signing-requests made to the acting CA in the chain of trust. Finally, a server X.509 certificate and private key are generated and signed by the VPN CA:

![alt text](https://github.com/security-man/aws-vpn-gateway/blob/main/AWS_VPN_Gateway_-_generate-pki.sh.png?raw=true)

# csr.py

This uses simple openssl commands and creates a client X.509 certificate and private key. The certificate is signed using the pre-existing VPN CA that was generated using generate-pki.sh (obtained from AWS SystemsManager). The python script takes as input a username and can be executed multiple times with different usernames to create multiple client certificates for multiple users. The signed certificate and key are then used to create a correctly-formatted .ovpn config file that can be used with any OpenVPN client to make a connection to the vpn gateway:

![alt text](https://github.com/security-man/aws-vpn-gateway/blob/main/AWS_VPN_Gateway_-_csr.py.png?raw=true)

## How to use this repository

- execute generate-pki.sh in the terraform/pki sub-directory (1-time only)
- execute terraform plan/apply to create AWS resources (1-time only)
- execute csr.py python file to generate client .ovpn config file (create client certificates on demand)
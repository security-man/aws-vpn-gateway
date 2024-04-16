#!/bin/bash

openssl genrsa -out root.ca.private.key.pem 4096

openssl req -new -x509 -config openssl.conf -section req_ca -sha512 \
    -subj "/C=GB/ST=My State/L=My Locality/O=My Company/OU=DevOps/CN=root.ca.cert.private.mydomain.com/emailAddress=devops@mycompany.com" \
    -days 3650 -set_serial 0x1 -key root.ca.private.key.pem -out root.ca.crt.pem

openssl genrsa -out intermediate.ca.private.key.pem 4096

openssl req -new -config openssl.conf -section req_ca -sha512 \
    -subj "/C=GB/ST=My State/L=My Locality/O=My Company/OU=DevOps/CN=intermediate.ca.cert.private.mydomain.com/emailAddress=devops@mycompany.com" \
    -key intermediate.ca.private.key.pem -out intermediate.ca.csr.pem

openssl req -x509 -config openssl.conf -section req_ca -sha512 \
    -CA root.ca.crt.pem -CAkey root.ca.private.key.pem \
    -days 1825 -set_serial 0x2 -in intermediate.ca.csr.pem -key intermediate.ca.private.key.pem -out intermediate.ca.crt.pem

openssl genrsa -out cvpn.ca.private.key.pem 2048

openssl req -new -config openssl.conf -section req_ca -sha512 \
    -subj "/C=GB/ST=My State/L=My Locality/O=My Company/OU=DevOps/CN=cvpn.ca.cert.private.mydomain.com/emailAddress=devops@mycompany.com" \
    -key cvpn.ca.private.key.pem -out cvpn.ca.csr.pem

openssl req -x509 -config openssl.conf -section req_ca -sha512 \
    -CA intermediate.ca.crt.pem -CAkey intermediate.ca.private.key.pem \
    -days 1095 -set_serial 0x3 -in cvpn.ca.csr.pem -key cvpn.ca.private.key.pem -out cvpn.ca.crt.pem

cat root.ca.crt.pem intermediate.ca.crt.pem > cvpn.ca.crt.chain.pem

openssl genrsa -out cvpn-server.private.key.pem 2048

openssl req -new -config openssl.conf -section req_tls_server -sha512 \
    -subj "/C=GB/ST=My State/L=My Locality/O=My Company/OU=DevOps/CN=cvpn-server.cvpn.cert.private.mydomain.com/emailAddress=devops@mycompany.com" \
    -key cvpn-server.private.key.pem -out cvpn-server.csr.pem

openssl req -x509 -config openssl.conf -section req_tls_server -sha512 \
    -CA cvpn.ca.crt.pem -CAkey cvpn.ca.private.key.pem \
    -days 1095 -set_serial 0x4 -in cvpn-server.csr.pem -key cvpn-server.private.key.pem -out cvpn-server.crt.pem

cat root.ca.crt.pem intermediate.ca.crt.pem cvpn.ca.crt.pem > cvpn-server.crt.chain.pem
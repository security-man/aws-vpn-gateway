#!/bin/bash

openssl genrsa -out $CVPN_USERNAME.private.key.pem 2048

openssl req -new -config openssl.conf -section req_tls_client -sha512 \
    -subj "/C=GB/ST=My State/L=My Locality/O=My Company/OU=DevOps/CN=$CVPN_USERNAME.cvpn.cert.private.mydomain.com/emailAddress=$CVPN_USERNAME@mycompany.com" \
    -key $CVPN_USERNAME.private.key.pem -out $CVPN_USERNAME.csr.pem

openssl req -x509 -config openssl.conf -section req_tls_client -sha512 \
    -CA cvpn.ca.crt.pem -CAkey cvpn.ca.private.key.pem \
    -days 365 -set_serial 0x5 -in $CVPN_USERNAME.csr.pem -key $CVPN_USERNAME.private.key.pem -out $CVPN_USERNAME.crt.pem
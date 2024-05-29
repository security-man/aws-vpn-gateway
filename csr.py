import subprocess
import boto3
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
import warnings
import os
warnings.simplefilter("ignore")

# Parse command line arguments
parser = ArgumentParser(formatter_class=ArgumentDefaultsHelpFormatter)
parser.add_argument("-u", "--username", default="user", help="Username for client certificate")
parser.add_argument("-r", "--region", default="eu-west-2", help="AWS region")
parser.add_argument("-p", "--profile", default="default", help="AWS profile for authentication / authorisation, as managed through aws cli .config file")
parser.add_argument("-cakey", "--cakey", default="private_cvpn_ca_private_key", help="Name of SSM parameter storing CA key")
parser.add_argument("-cacert", "--cacert", default="private_cvpn_ca_certificate", help="Name of SSM parameter storing CA certificate")
parser.add_argument("-cacsr", "--cacsr", default="private_cvpn_ca_chain_certificate", help="Name of SSM parameter storing CA certificate signing request")
args = vars(parser.parse_args())

# Set up parameters
username = args["username"]
region = args["region"]
profile = args["profile"]
ssm_ca_key_name = args["cakey"]
ssm_ca_cert_name = args["cacert"]
ssm_ca_csr_name = args["cacsr"]

# get CA cert, key, key chain
session = boto3.Session(profile_name=profile,region_name=region)
ssm_client = session.client('ssm')
ssm_ca_key_response = ssm_client.get_parameter(Name=ssm_ca_key_name,WithDecryption=True)
ca_key = ssm_ca_key_response['Parameter']['Value']
ssm_ca_cert_response = ssm_client.get_parameter(Name=ssm_ca_cert_name,WithDecryption=True)
ca_cert = ssm_ca_cert_response['Parameter']['Value']
ssm_ca_cert_chain_response = ssm_client.get_parameter(Name=ssm_ca_csr_name,WithDecryption=True)
ca_cert_chain = ssm_ca_cert_chain_response['Parameter']['Value']
file_ca_cert = open("ca_cert","w") # files written temporarily, deleted during clean-up at bottom of code
file_ca_cert.write(ca_cert)
file_ca_cert.close()
file_ca_key = open("ca_key","w")
file_ca_key.write(ca_key)
file_ca_key.close()

# generate client key, csr, client cert using openssl
subprocess.call(["openssl","genrsa","-out",username + ".private.key.pem","2048"])
subprocess.call(["openssl","req","-new","-config",
                 "./terraform/pki/openssl.conf",
                 "-section","req_tls_client","-sha512",
                 "-subj","/C=GB/ST=My State/L=My Locality/O=My Company/OU=DevOps/CN=" + username + ".cvpn.cert.private.mydomain.com/emailAddress="
                   + username + "@mycompany.com","-key",username + ".private.key.pem","-out",username + ".csr.pem"])
subprocess.call(["openssl","req","-x509","-config",
                 "./terraform/pki/openssl.conf",
                 "-section","req_tls_client","-sha512",
                 "-CA","ca_cert","-CAkey","ca_key","-days","90","-set_serial","0x5","-in",username + ".csr.pem","-key",
                 username + ".private.key.pem","-out",username + ".crt.pem"])

# get ovpn file
ec2_client = session.client('ec2')
cvpn_id_response = ec2_client.describe_client_vpn_endpoints()
cvpn_id = cvpn_id_response['ClientVpnEndpoints'][0]['ClientVpnEndpointId'] # Assumes only 1 client VPN present in account
cvpn_config_response = ec2_client.export_client_vpn_client_configuration(ClientVpnEndpointId=cvpn_id,DryRun=False)
ovpn_config = cvpn_config_response['ClientConfiguration']

# reformat ovpn file and inject new client cert and key
with open(username + ".crt.pem") as cert_file:
    client_cert = cert_file.read()
with open(username + ".private.key.pem") as key_file:
    client_key = key_file.read()
ovpn_split = ovpn_config.split("</ca>")
ovpn_split[0] = ovpn_split[0] + "\n</ca>" + "\n<cert>\n" + client_cert + "\n\n</cert>" + "\n<key>\n" + client_key + "\n\n</key>\n"
ovpn_final = ovpn_split[0] + ovpn_split[1]
file_ovpn = open(username + ".ovpn","w")
file_ovpn.write(ovpn_final)
file_ovpn.close()

# cleanup
os.remove("ca_cert")
os.remove("ca_key")
os.remove(username + ".crt.pem")
os.remove(username + ".csr.pem")
os.remove(username + ".private.key.pem")
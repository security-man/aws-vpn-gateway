import boto3
import subprocess
import os

def read_tfvars(path,variable):
    with open(path, 'r') as file:
        lines = file.readlines()
        for line in lines:
            if line.find(variable) != -1:
                new_line = line.split("=")
                var = new_line[1].strip()
                var_raw = var.split("\"")
                return var_raw[1]

CVPN_USERNAME = os.environ['CVPN_USERNAME']
# subprocess.run(["./terraform/pki/generate-client.sh"],cwd="~/terraform/pki/")

with open("./terraform/pki/" + CVPN_USERNAME + ".crt.pem") as cert_file:
    cert = cert_file.read()

with open("./terraform/pki/" + CVPN_USERNAME + ".private.key.pem") as key_file:
    key = key_file.read()

region = read_tfvars("./terraform/terraform.tfvars","region")
profile = read_tfvars("./terraform/terraform.tfvars","profile")

session = boto3.Session(profile_name=profile,region_name=region)
client = session.client('ec2')

with open("./terraform/cvpn_id") as cvpn_id_file:
    cvpn_id = cvpn_id_file.read()

response = client.export_client_vpn_client_configuration(ClientVpnEndpointId=cvpn_id,DryRun=False)
ovpn = response['ClientConfiguration']
ovpn_split = ovpn.split("</ca>")
ovpn_split[0] = ovpn_split[0] + "\n</ca>" + "\n<cert>\n" + cert + "\n\n</cert>" + "\n<key>\n" + key + "\n\n</key>\n"
ovpn_final = ovpn_split[0] + ovpn_split[1]
file = open(CVPN_USERNAME + ".ovpn","w")
file.write(ovpn_final)
file.close()
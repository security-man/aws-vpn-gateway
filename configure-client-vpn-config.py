import boto3

with open("./terraform/pki/zlaker.crt.pem") as cert_file:
    cert = cert_file.read()

with open("./terraform/pki/zlaker.private.key.pem") as key_file:
    key = key_file.read()

session = boto3.Session(profile_name='564059153434-Admin',region_name='eu-west-2')
client = session.client('ec2')
response = client.export_client_vpn_client_configuration(ClientVpnEndpointId='cvpn-endpoint-04537ac29a4211ef4',DryRun=False)
ovpn = response['ClientConfiguration']
ovpn_split = ovpn.split("</ca>")
ovpn_split[0] = ovpn_split[0] + "\n</ca>" + "\n<cert>\n" + cert + "\n\n</cert>" + "\n<key>\n" + key + "\n\n</key>\n"
ovpn_final = ovpn_split[0] + ovpn_split[1]
file = open("newclientconfig.ovpn","w")
file.write(ovpn_final)
file.close()
import bs4
import utils

#utils.disable_strict_host_key_checking()

config_file = 'config.xml'

with open(config_file, 'r') as f:
    xml = f.read()
    soup = bs4.BeautifulSoup(xml, 'lxml')

interfaces = list(soup.find_all('login'))
user_name = [interface["username"] for interface in interfaces][0]
print("user_name:", user_name)

ssh_endpoints = [interface["hostname"] for interface in interfaces]
for ep in ssh_endpoints:
    print(f"{ep}")


ssh_endpoints = list(set(ssh_endpoints))

rac_servers = ssh_endpoints
with open("servers.txt", "w") as f:
    for server in ssh_endpoints:
        f.write(user_name+"@"+server+'\n')

import bs4
import utils

#utils.disable_strict_host_key_checking()

config_file = 'config.xml'

with open(config_file, 'r') as f:
    xml = f.read()
    soup = bs4.BeautifulSoup(xml, 'lxml')

interfaces = list(soup.find_all('login'))
ssh_endpoints = [interface["hostname"] for interface in interfaces]

print(f"ssh_endpoints: {ssh_endpoints}")

rac_servers = ssh_endpoints

print(f"rac_servers: {rac_servers}")

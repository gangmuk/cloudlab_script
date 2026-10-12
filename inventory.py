import bs4


config_file = 'config.xml'

with open(config_file, 'r') as f:
    xml = f.read()
    soup = bs4.BeautifulSoup(xml, 'lxml')

interfaces = list(soup.find_all('login'))
user_name = [interface["username"] for interface in interfaces][0]
print("user_name:", user_name)

# client_id (node0, node1, ...) -> login hostname
_node_hostnames = {}
for _node in soup.find_all('node'):
    for _login in _node.find_all('login'):
        if _login["username"] == user_name:
            _node_hostnames[_node["client_id"]] = _login["hostname"]
            break
for node_id, ep in sorted(_node_hostnames.items()):
    print(f"{node_id}: {ep}")

ssh_endpoints = sorted(set(_node_hostnames.values()))

rac_servers = ssh_endpoints
with open("servers.txt", "w") as f:
    for server in ssh_endpoints:
        f.write(user_name+"@"+server+'\n')

# node0 is the k8s master, everything else is a worker
with open("master.txt", "w") as f:
    f.write(user_name+"@"+_node_hostnames["node0"]+'\n')
with open("workers.txt", "w") as f:
    for node_id, server in sorted(_node_hostnames.items()):
        if node_id != "node0":
            f.write(user_name+"@"+server+'\n')

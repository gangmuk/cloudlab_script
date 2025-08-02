import xml.etree.ElementTree as ET
import os
import subprocess
import time

def parse_node_names(xml_file):
    # Parse the XML file
    tree = ET.parse(xml_file)
    root = tree.getroot()
    
    # Define the namespace mapping
    namespaces = {
        'rspec': 'http://www.geni.net/resources/rspec/3',
        'emulab': 'http://www.protogeni.net/resources/rspec/ext/emulab/1'
    }
    
    # Find all node elements
    nodes = root.findall('rspec:node', namespaces)
    
    # Dictionary to store node names
    node_names = {}
    
    # Extract hostname for each node
    for node in nodes:
        # Get the client_id (node0, node1, etc.)
        client_id = node.get('client_id')
        
        # Find the login service element that contains the hostname
        services = node.find('rspec:services', namespaces)
        if services is not None:
            login = services.find('rspec:login', namespaces)
            if login is not None:
                hostname = login.get('hostname')
                node_names[client_id] = hostname
    
    return node_names

def get_kubeadm_join_cmd(hostname):
    cmd = f"ssh gangmuk@{hostname} {home_dir}/get_kubeadm_cmd.sh"
    try:
        # Using subprocess.check_output to capture the command output
        result = subprocess.check_output(cmd, shell=True, text=True).strip()
        return result
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        return None
    
# Example usage
if __name__ == "__main__":
    node_names = parse_node_names('config.xml')
    for node_id, hostname in node_names.items():
        print(f"{node_id}: {hostname}")
    home_dir="/users/gangmuk/projects/cloudlab_script"
    
    # master
    join_cmd = None
    for node_id, hostname in node_names.items():
        if node_id == "node0":
            os.system(f"ssh gangmuk@{hostname} {home_dir}/install_basic_pkg_in_node0.sh")
            
            os.system(f"ssh gangmuk@{hostname} /users/gangmuk/.local/bin/pyinfra {home_dir}/inventory.py {home_dir}/deploy.py")
            
            os.system(f"ssh gangmuk@{hostname} {home_dir}/cloudlab_k8s_setup.sh master")
            time.sleep(5)
            join_cmd = get_kubeadm_join_cmd(hostname)
            print(f"Join command: {join_cmd}")
            
    
    # worker
    for node_id, hostname in node_names.items():
        if node_id != "node0":
            os.system(f"ssh gangmuk@{hostname} {home_dir}/cloudlab_k8s_setup.sh worker")
            time.sleep(5)
            if join_cmd:
                os.system(f"ssh gangmuk@{hostname} {join_cmd}")
            else:
                print("Error: kubeadm join command not found")
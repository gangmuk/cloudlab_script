import subprocess
import sys

def run_command(command):
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    process.wait()
    print(process.returncode)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python install_k8s.py <node0_key>")
        sys.exit(1)
    node0_key = sys.argv[1]
    with open("servers.txt") as f:
        lines = f.readlines()
        worker_list = list()
        master_node = ""
        for host in lines:
            host = host.strip()
            if node0_key not in host:
                worker_list.append(host)
            else:
                master_node = host
        for 
                role = "master"
                run_command(f"ssh {host} '/users/gangmuk/projects/cloudlab_script/cloudlab_k8s_setup.sh {role}'")
            else:
                role = "worker"
                run_command(f"pssh -i -h {host} '/users/gangmuk/projects/cloudlab_script/cloudlab_k8s_setup.sh {role}'")
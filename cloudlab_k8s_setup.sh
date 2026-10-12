#!/bin/bash

########################################################
# author: Chirag C. Shetty (cshetty2@illinois.edu)
# date: Sep 14, 2023 
# modified by: Gangmuk Lim (gangmuk2@illinois.edu)
# modified date: Nov 16, 2023
########################################################

# Export noninteractive frontend to prevent prompts
export DEBIAN_FRONTEND=noninteractive

sleep_func () {
    echo "Next command will be executed in 2 seconds"
    for i in {2..1}
    do
        echo "$i"
        sleep 1
    done
}

#########################
# Set default terminal width if tput fails
DEFAULT_TERM_WIDTH=80

dividerInstruction () {
    width="${COLUMNS:-$(tput cols 2>/dev/null || echo $DEFAULT_TERM_WIDTH)}"
    printf '%*s\n' "$width" '' | tr ' ' -;
}
dividerAttention () {
    width="${COLUMNS:-$(tput cols 2>/dev/null || echo $DEFAULT_TERM_WIDTH)}"
    printf '%*s\n' "$width" '' | tr ' ' '*';
}
dividerAction () {
    width="${COLUMNS:-$(tput cols 2>/dev/null || echo $DEFAULT_TERM_WIDTH)}"
    printf '%*s\n' "$width" '' | tr ' ' +;
}
dividerEnd () {
    width="${COLUMNS:-$(tput cols 2>/dev/null || echo $DEFAULT_TERM_WIDTH)}"
    printf '%*s\n' "$width" '' | tr ' ' =;
}
###########################

node_type=$1
master=master
worker=worker
if [ "$node_type" != "$master" ] && [ "$node_type" != "$worker" ]
then
    echo "Invalid node type: ${node_type}"
    echo "The valid input is either master or worker"
    exit
fi
echo node_type: ${node_type}
sleep_func

echo -e "\nThis script must be run once on EACH node you want in the cluster"
echo -e "Recommended: \n1. Run all scripts TOGETHER on all machines so that you can collect the ip data to be added to /etc/hosts"
echo -e "\n2. Keep 'node0' - as named by cloudlab - in the cluster. It will be made the k8smaster by this script. Else you need to manually edit the /etc/hosts file"
sleep_func

######################## Setup /etc/hosts settings #############################
dividerAction
echo "In cloudlab, nodes reserved as a cluster are named node0, node1, node2 etc. By default we will define 'node0' as the control-plane node or 'k8smaster'. All other node<i> will be named k8sworker<i> in /etc/hosts"
echo -e "\nNOTE: If you want to manually change the etc/hosts different from this convention, skip next step"

hosts_detail_path="hosts_detail.txt"
echo "Read ${hosts_detail_path} file"
if [ -f "${hosts_detail_path}" ]; then
    echo -e "\n${hosts_detail_path} exists."
    cat ${hosts_detail_path}
    sleep_func
else
    echo -e "\nError: ${hosts_detail_path} does NOT exists."
    kill -INT $$   # Equivalent of CTRL+C
fi

dividerInstruction

## Append hosts_detail.txt to /etc/hosts (skip lines that are already there)
while IFS= read -r line; do
    grep -qxF "$line" /etc/hosts || echo "$line" | sudo tee -a /etc/hosts
done < ${hosts_detail_path}
dividerInstruction
#Check
cat /etc/hosts

##############################################################################

# Update package list
sudo apt-get update -y

## Execute beneath swapoff and sed command to disable swap.
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

## Kernel modules
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

## Reload the above changes
sudo sysctl --system

## Verify the modules are running
lsmod | grep br_netfilter
lsmod | grep overlay
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

## Install Containerd runtime
sudo apt-get install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

##########################################
echo "Installing Docker and containerd:"
echo "" 

sudo apt-get update -y
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo -e "Checking Docker:\n"

# Configure Docker to use /mnt/docker as data directory
echo "Configuring Docker to use /mnt/docker as data directory"
sudo mkdir -p /mnt/docker
sudo mkdir -p /etc/docker

# Stop Docker service if running
sudo systemctl stop docker 2>/dev/null || true

# Create daemon.json with custom data-root
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "data-root": "/mnt/docker"
}
EOF

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

sudo usermod -aG docker $USER
echo "1"

########################################

containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
# Kubernetes images live in containerd's root, so keep it on the /mnt disk too
sudo mkdir -p /mnt/containerd
sudo sed -i "s|^root = .*|root = '/mnt/containerd'|" /etc/containerd/config.toml
echo "1"
sudo sed -i 's|sandbox_image = "registry.k8s.io/pause:3.*|sandbox_image = "registry.k8s.io/pause:3.9"|' /etc/containerd/config.toml
echo "1"

# Restart and enable containerd service
sudo systemctl restart containerd
sudo systemctl enable containerd
echo "1"

# new package location
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "1"

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
echo "1"

###################################################################################

dividerAction

dividerAttention

IFS='.'
my_string=$HOSTNAME
read -ra my_array <<< "$my_string"
for nodename in "${my_array[@]}"; do
    break
done
echo $nodename
IFS=$' \t\n'
sleep_func
echo "1"

if [ $node_type == $master ]
then
    echo "THIS IS MASTER NODE (nodename: $nodename)"
    echo "We will execute kubeadm init and apply network"
    sleep_func
    ### Install helm
    curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    bash /tmp/get_helm.sh    # needs bash, not sh (dash)
    ################
    echo ""
    network_type='f'
    
    if [ $network_type == 'c' ]
    then
        ## Calico
        echo -e "RUN and wait: \n  sudo kubeadm init --control-plane-endpoint=$HOSTNAME"
        sudo kubeadm init --control-plane-endpoint=$HOSTNAME
    else
        ## Flannel
        echo -e "RUN and wait: \n  sudo kubeadm init --control-plane-endpoint=$HOSTNAME --pod-network-cidr=10.244.0.0/16 "
        sudo kubeadm init --control-plane-endpoint=$HOSTNAME --pod-network-cidr=10.244.0.0/16
    fi

    echo "setup .kube/config"
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    echo "apply network"
    if [ $network_type == 'c' ]
    then
        kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml ## calico
    else
        kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml ## flannel
    fi

    dividerAttention
    echo "** COPY AND RUN THE FOLLOWING COMMAND LINE IN WORKER NODE**"
    echo "sudo $(sudo kubeadm token create --print-join-command)"
    dividerAttention
else
    echo "THIS IS WORKER NODE (nodename: $nodename)"
    echo "You should run kubeadm join command in worker node"
    echo -e "Note down the command from master node to join the k8s network and run"
fi
echo "1"

echo "Script complete"
dividerAttention
echo ""

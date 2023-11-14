#######################################################
## Run it ONLY on the MASTER node NOT on worker node ##
#######################################################

IFS='.'
for element in $HOSTNAME; do
  nodename="$element"
  break  # Exit the loop after the first iteration
done
IFS=$' \t\n'
if [ ${nodename} != "node0" ]
then
	echo "This is NOT master node (nodename: ${nodename})"
	echo "exit..."
	exit
fi

## kubeadm control plane initialization
sudo kubeadm init --control-plane-endpoint=$HOSTNAME --pod-network-cidr=10.244.0.0/16 ## flannel
#sudo kubeadm init --control-plane-endpoint=$HOSTNAME ## calico

## setup .kube/config
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

## network apply
sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml ## flannel
#kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml ## calico

## This information needs to be stored in file to use in worker node joining. 
token=$(kubeadm token list | sed -n '2p' | awk '{print $1}')
cert_hash=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt \
    | openssl rsa -pubin -outform der 2>/dev/null \
    | openssl dgst -sha256 -hex \
    | sed 's/^.* //')
echo control_plane_hostname: $HOSTNAME
echo token: $token
echo cert_hash: $cert_hash
filename=join_worker_node.sh
echo "kubeadm join ${HOSTNAME} --token ${token} --discovery-token-ca-cert-hash ${cert_hash}" > ${filename} ## worker node
#echo "kubeadm join ${HOSTNAME} --token ${token} --discovery-token-ca-cert-hash ${cert_hash} --control-plane" > ${filename} ## adding more control-plane
chmod +x ${filename}

#python inventory.py
ip_file=servers.txt
kubeconfig_file="~/.kube/config"
while IFS= read -r line; do
    lines+=("$line")
    done < ${ip_file}
for line in "${lines[@]}"; do
    echo "scp ${filename} to $line"
	scp ${filename} ${line}:/users/gangmuk/projects/cloudlab_script
    scp ${kubeconfig_file}  ${line}:${kubeconfig_file}
done

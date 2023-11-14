## This should run on the master node not on worker node

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
control_plane_hostname="node0.gangmuk-178410.istio-pg0.cloudlab.umass.edu:6443"
echo control_plane_hostname: $control_plane_hostname
echo token: $token
echo cert_hash: $cert_hash

echo "kubeadm join ${control_plane_hostname} --token ${token} --discovery-token-ca-cert-hash ${cert_hash} --control-plane" > join_worker_node.sh
chmod +x join_worker_node.sh

python inventory.py
ip_file=servers.txt
while IFS= read -r line; do
    lines+=("$line")
    done < ${ip_file}
for line in "${lines[@]}"; do
    echo "scp join_worker_node.sh to $line"
	scp join_worker_node.sh ${line}:/users/gangmuk/projects/cloudlab_script
done

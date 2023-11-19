#######################################################
## Run it ONLY on the MASTER node NOT on worker node ##
#######################################################

## setup .kube/config
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

## network apply
sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml ## flannel
#kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml ## calico

token=$(kubeadm token list | sed -n '2p' | awk '{print $1}')
cert_hash=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt \
    | openssl rsa -pubin -outform der 2>/dev/null \
    | openssl dgst -sha256 -hex \
    | sed 's/^.* //')
echo "** COPY AND RUN THE FOLLOWING COMMAND LINE IN WORKER NODE**"
echo "sudo kubeadm join ${HOSTNAME}:6443 --token ${token} --discovery-token-ca-cert-hash sha256:${cert_hash}"
#echo "sudo kubeadm join ${HOSTNAME} --token ${token} --discovery-token-ca-cert-hash ${cert_hash} --control-plane"

sudo kubeadm init --control-plane-endpoint=node0.gangmuk-178336.istio-pg0.clemson.cloudlab.us --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# For control-plane node to join the cluster
kubeadm join node0.gangmuk-178336.istio-pg0.clemson.cloudlab.us:6443 --token ks2422.47fxndd8osiawzmw --discovery-token-ca-cert-hash sha256:179157460cb5bb373750a7f6c59f2ce579acf52885f191eb69c115bcc40778c2 --control-plane


# For worker node to join the cluster
kubeadm join node0.gangmuk-178336.istio-pg0.clemson.cloudlab.us:6443 --token ks2422.47fxndd8osiawzmw --discovery-token-ca-cert-hash sha256:179157460cb5bb373750a7f6c59f2ce579acf52885f191eb69c115bcc40778c2

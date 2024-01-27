node=$1

if [ -z $node ]
then
    echo node argument is empty
    exit
fi

kubectl drain --ignore-daemonsets $node;
kubectl delete $node;
kubeadm reset
sudo apt-get purge kubeadm kubectl kubelet kubernetes-cni kube*
sudo apt-get autoremove
sudo rm -rf ~/.kube
sudo rm -fr /etc/kubernetes/;
sudo rm -fr /var/lib/etcd;
sudo rm -rf /var/lib/cni/;
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
docker rm -f `docker ps -a | grep "k8s_" | awk '{print $1}'`


# Clear the iptables
iptables -F && iptables -X
iptables -t nat -F && iptables -t nat -X
iptables -t raw -F && iptables -t raw -X
iptables -t mangle -F && iptables -t mangle -X

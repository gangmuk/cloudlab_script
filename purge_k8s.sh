#!/bin/bash

# Reset Kubernetes cluster
kubeadm reset

# Purge all Kubernetes-related packages
sudo apt-get purge kubeadm kubectl kubelet kubernetes-cni kube* -y --allow-change-held-packages
sudo apt-get autoremove -y

sudo ip link delete cni0

# Clean up remaining Kubernetes directories
sudo rm -rf ~/.kube
sudo rm -rf /etc/cni
sudo rm -rf /etc/kubernetes
sudo rm -rf /var/lib/etcd

# Unmount busy kubelet directories
echo "Checking and unmounting busy volumes..."
for mount in $(mount | grep "/var/lib/kubelet" | awk '{print $3}'); do
  echo "Unmounting $mount"
  sudo umount -l "$mount"
done

# Remove kubelet data directory after unmounting
sudo rm -rf /var/lib/kubelet

# Flush iptables rules
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X

echo "Kubernetes reset and cleanup complete!"

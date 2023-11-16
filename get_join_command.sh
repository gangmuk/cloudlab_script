token=$(kubeadm token list | sed -n '2p' | awk '{print $1}')
cert_hash=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt \
    | openssl rsa -pubin -outform der 2>/dev/null \
    | openssl dgst -sha256 -hex \
    | sed 's/^.* //')
echo "sudo kubeadm join ${HOSTNAME}:6443 --token ${token} --discovery-token-ca-cert-hash sha256:${cert_hash}"

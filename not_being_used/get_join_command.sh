'''
A token is valid only for 24 hours.
If you want to join a new worker node in 24 hours after you created the last token, you have to generate a new token.

1. To generate a new token, run the following command in the master node.
- kubeadm token generate

2. To get join command, run the following command in the master node.
- kubeadm token create [token] --print-join-command

3. Copy the output command of step 2 and run this command in a new worker node that you want to join with sudo
'''
token=$(kubeadm token list | sed -n '2p' | awk '{print $1}')

if [ $token == "" ]
then
    echo "The last token is expired."
    echo "Run 'kubeadam token generate' to generate a new token"
    exit
fi
cert_hash=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt \
    | openssl rsa -pubin -outform der 2>/dev/null \
    | openssl dgst -sha256 -hex \
    | sed 's/^.* //')
echo "sudo kubeadm join ${HOSTNAME}:6443 --token ${token} --discovery-token-ca-cert-hash sha256:${cert_hash}"

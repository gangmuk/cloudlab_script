#!/bin/bash


# bashrc='~/.bashrc'
# # kubectl=\'kubectl\'

# pssh -i -h servers.txt "echo 'export PATH=\$PATH:\$HOME/.local/bin' >> ${bashrc}"
# pssh -i -h servers.txt "echo 'export PATH=\$PATH:\$HOME/projects/SLATE/sh' >> ${bashrc}"
# pssh -i -h servers.txt "echo 'export PATH=\$PATH:\$HOME/projects/all-the-scripts/aibrix' >> ${bashrc}"
# pssh -i -h servers.txt "echo 'export PATH=\$PATH:\$HOME/projects/all-the-scripts/k8s' >> ${bashrc}"
# pssh -i -h servers.txt "echo 'HISTSIZE=50000' >> ${bashrc}"
# pssh -i -h servers.txt "echo 'HISTFILESIZE=50000' >> ${bashrc}"
# pssh -i -h servers.txt "echo alias k=kubectl >> ${bashrc}"
# pssh -i -h servers.txt "echo alias ka=kubectl -n aibrix-system >> ${bashrc}"
# pssh -i -h servers.txt "export PATH=\$PATH:\$HOME/projects/all-the-scripts/aibrix"
# pssh -i -h servers.txt "export PATH=\$PATH:\$HOME/projects/all-the-scripts/k8s"
# pssh -i -h servers.txt "export KUBECONFIG=\$KUBECONFIG:\$HOME/.kube/config:\$HOME/.kube/config-vke:\$HOME/.kube/config-local-kind:\$HOME/.kube/config-eks-east"

# pssh -i -h servers.txt "echo 'export LS_COLORS=\$LS_COLORS:'*.pdf=38;5;208:' >> ${bashrc}"
# pssh -i -h servers.txt "echo 'export LS_COLORS=\$LS_COLORS:'*.png=37;5;208:' >> ${bashrc}"
# pssh -i -h servers.txt "source ~/.bashrc"
pscp -h servers.txt bashrc_for_server /users/gangmuk/.bashrc
pscp -h servers.txt vimrc_for_server /users/gangmuk/.vimrc

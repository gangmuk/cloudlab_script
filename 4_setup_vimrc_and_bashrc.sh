#!/bin/bash


bashrc='~/.bashrc'
kubectl=\'kubectl\'

pssh -i -h servers.txt "echo 'export PATH=\$PATH:/users/gangmuk/.local/bin' >> ${bashrc}"
pssh -i -h servers.txt "echo 'export PATH=\$PATH:/users/gangmuk/projects/SLATE/sh' >> ${bashrc}"
pssh -i -h servers.txt "echo 'HISTSIZE=50000' >> ${bashrc}"
pssh -i -h servers.txt "echo 'HISTFILESIZE=50000' >> ${bashrc}"
pssh -i -h servers.txt "echo alias k=${kubectl} >> ${bashrc}"
pssh -i -h servers.txt "export PATH=\$PATH:/users/gangmuk/projects/all-the-scripts/aibrix"
pssh -i -h servers.txt "export PATH=\$PATH:/users/gangmuk/projects/all-the-scripts/k8s"
pssh -i -h servers.txt "export KUBECONFIG=\$KUBECONFIG:/users/gangmuk/.kube/config:/users/gangmuk/.kube/config-vke"
pssh -i -h servers.txt "echo 'ulimit -n 1048576' >> ${bashrc}"

pssh -i -h servers.txt "echo 'export LS_COLORS=\$LS_COLORS:'*.pdf=38;5;208:' >> ${bashrc}"

pssh -i -h servers.txt "source ~/.bashrc"

pscp -h servers.txt ~/.vimrc /users/gangmuk/

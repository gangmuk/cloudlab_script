#!/bin/bash


bashrc='~/.bashrc'
kubectl=\'kubectl\'

pssh -i -h servers.txt "echo 'export PATH=\$PATH:/users/gangmuk/.local/bin' >> ${bashrc}"
pssh -i -h servers.txt "echo 'export PATH=\$PATH:/users/gangmuk/projects/SLATE/sh' >> ${bashrc}"
pssh -i -h servers.txt "echo 'HISTSIZE=50000' >> ${bashrc}"
pssh -i -h servers.txt "echo 'HISTFILESIZE=50000' >> ${bashrc}"
pssh -i -h servers.txt "echo alias k=${kubectl} >> ${bashrc}"
pssh -i -h servers.txt "source ~/.bashrc"

pscp -h servers.txt ~/.vimrc /users/gangmuk/
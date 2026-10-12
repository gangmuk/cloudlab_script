#!/bin/bash
# Run on the master node. Creates a fresh token (tokens expire after 24h) and prints the full join command.
echo "** COPY AND RUN THE FOLLOWING COMMAND LINE IN WORKER NODE**"
echo "sudo $(sudo kubeadm token create --print-join-command)"

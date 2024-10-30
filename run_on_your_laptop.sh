#!/bin/bash

./0_init_server_list.sh

echo "THIS IS THE LIST OF SERVERS"
echo "==========================="
cat servers.txt
echo "==========================="
echo "IT WILL START IN 5 SECONDS"
for i in {5..1}; do
    echo $i
    sleep 1
done

./1_ssh_copy.sh

./2_mkdir_gitclone.sh

./2.5_gitclone_private_repo.sh

./3_create_hosts_detail.sh

./4_setup_vimrc_and_bashrc.sh

./5_add_line_to_bashrc.sh

./6_copy_gurobi_wls.sh
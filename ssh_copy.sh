#!/bin/bash

echo "run inventory.py to get the ips of all servers in the cluster"
echo "it will write them in servers.txt"
python inventory.py # you need config.xml from cloudlab manifest

echo "read servers.txt file"
while IFS= read -r line; do
    t=1
    done < servers.txt

echo "collected ip addresses"
for val in $line; do
    echo $val
done

user_name="gangmuk"
ssh_path="/users/${user_name}/.ssh"
auth_key_path="authorized_keys"
temp_local_file="all_keys.txt"

##########################
## ssh-keygen in each cloudlab node
##########################
for val in $line; do
    echo "ssh ${user_name}@${val} ssh-keygen"
    ssh ${user_name}@${val} ssh-keygen
done
echo "ssh-keygen done"

##########################
## fetching the generated public key (id_rsa.pub) of each node
## and write them in local file
##########################
for val in $line; do
    echo "fetching ${val}'s public key into ${temp_local_file}"
    ssh ${user_name}@${val} cat /users/gangmuk/.ssh/id_rsa.pub >> ${temp_local_file}
done
echo "aggregating all servers' keys into ${temp_local_file}"

##########################
## scp the local file having all public keys to all nodes
##########################
for val in $line; do
    echo "scp ${temp_local_file} to ${val}:${ssh_path}"
    scp ${temp_local_file} ${user_name}@${val}:${ssh_path}
done
echo "scp all_key file to all server"

##########################
## append publics to authorized_keys in each node
##########################
for val in $line; do
    echo "${val}, append all_key file to authorized_keys"
    ssh ${user_name}@${val} "cat ${ssh_path}/${temp_local_file} >> ${ssh_path}/${auth_key_path}"
done
echo "append all_key file to authorized_keys done"
##########################

#rm ${temp_local_file}

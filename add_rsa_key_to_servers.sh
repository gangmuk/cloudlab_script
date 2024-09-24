#!/bin/bash

user_name="gangmuk"
ssh_path="/users/${user_name}/.ssh"
auth_key_path="authorized_keys"
ip_file="servers.txt"

python inventory.py &&

echo "read servers.txt file"
while IFS= read -r line; do
    lines+=("$line")
    done < ${ip_file}

for line in "${lines[@]}"; do
    echo "$line"
done

new_key=""

for line in "${lines[@]}"; do
    ssh ${line} "echo ${new_key}  >> ${ssh_path}/${auth_key_path}"
done


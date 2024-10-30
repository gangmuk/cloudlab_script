#!/bin/bash

user_name="gangmuk"
ssh_path="/users/${user_name}/.ssh"
auth_key_path="authorized_keys"
ip_file="servers.txt"

echo "read servers.txt file"
while IFS= read -r line; do
    lines+=("$line")
    done < ${ip_file}

for line in "${lines[@]}"; do
    echo "$line"
done

new_key_1=""

if [ -z "${new_key_1}" ]; then
    echo "new_key_1 is empty"
    exit 1
fi

# all_keys=("${new_key_1}" "${new_key_2}" "${new_key_3}")
all_keys=("${new_key_3}")

for line in "${lines[@]}"; do
    for key in "${all_keys[@]}"; do
        ssh ${line} "echo ${key}  >> ${ssh_path}/${auth_key_path}"
    done
done


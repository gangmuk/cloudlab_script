#!/bin/bash

user_name="gangmuk"
ssh_path="/users/${user_name}/.ssh"
auth_key_path="authorized_keys"
temp_local_file="all_keys.txt"
ip_file="servers.txt"

python inventory.py &&

echo "read servers.txt file"
while IFS= read -r line; do
    lines+=("$line")
    done < ${ip_file}

for line in "${lines[@]}"; do
    echo "$line"
done

# echo "ssh-keygen"
# for line in "${lines[@]}"; do
#     ssh ${line} ssh-keygen
# done

pscp -h servers.txt ssh_key_gen_script.sh /users/gangmuk &&
pssh -i -h servers.txt "bash /users/gangmuk/ssh_key_gen_script.sh" &&

echo "fetching public key into ${temp_local_file}"
for line in "${lines[@]}"; do
    ssh ${line} cat /users/gangmuk/.ssh/id_rsa.pub >> ${temp_local_file}
done

echo "scp ${temp_local_file}"
for line in "${lines[@]}"; do
    scp ${temp_local_file} ${line}:${ssh_path}
done

echo "append all_key file to authorized_keys"
for line in "${lines[@]}"; do
    ssh ${line} "cat ${ssh_path}/${temp_local_file} >> ${ssh_path}/${auth_key_path}"
done

rm ${temp_local_file}

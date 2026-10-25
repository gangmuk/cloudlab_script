#!/bin/bash
#
# Every node gets its own ssh key (kept if it already has one), and every node accepts the keys
# of all nodes plus extra_authorized_keys.txt (Delta, Delta AI).
#
# The keys go in ~/.ssh/authorized_keys2, not authorized_keys: CloudLab's account software
# regenerates authorized_keys from the portal key list (e.g. after a key change in the web UI),
# which drops anything added there. sshd reads both files.

user_name="gangmuk"
ssh_path="/users/${user_name}/.ssh"
auth_key_path="authorized_keys2"
temp_local_file="all_keys.txt"
ip_file="servers.txt"

python inventory.py || exit 1

while IFS= read -r line; do
    lines+=("$line")
done < ${ip_file}

pscp -h servers.txt ssh_key_gen_script.sh /users/gangmuk || exit 1
pssh -i -h servers.txt "bash /users/gangmuk/ssh_key_gen_script.sh" || exit 1

echo "fetching public keys into ${temp_local_file}"
rm -f ${temp_local_file}
for line in "${lines[@]}"; do
    ssh ${line} cat ${ssh_path}/id_rsa.pub >> ${temp_local_file} || { echo "could not read the key of ${line}"; exit 1; }
done

# Keys of other machines that should reach the nodes (e.g. Delta login nodes)
if [ -f extra_authorized_keys.txt ]; then
    grep -v '^#' extra_authorized_keys.txt | grep -v '^[[:space:]]*$' >> ${temp_local_file}
fi

echo "add missing keys from ${temp_local_file} to ${auth_key_path}"
status=0
for line in "${lines[@]}"; do
    ssh ${line} "f=${ssh_path}/${auth_key_path}; touch \$f && chmod 600 \$f && \
        while IFS= read -r k; do grep -qxF \"\$k\" \$f || echo \"\$k\" >> \$f; done" < ${temp_local_file} \
        && echo "${line}: ok" || { echo "${line}: FAILED"; status=1; }
done

rm ${temp_local_file}
exit ${status}

#!/bin/bash

user_name=gangmuk
ip_file=servers.txt
project_dir=/users/${user_name}/projects/cloudlab_script

python inventory.py

while IFS= read -r line; do
    lines+=("$line")
    done < ${ip_file}
for line in "${lines[@]}"; do
    echo "$line"
done

#git pull
#git archive --format=tar -o my_repo.tar -v HEAD
tar cvf my_repo.tar *

echo "rm existing projects dir"
pssh -i -h ${ip_file} "rm -rf /users/${user_name}/projects"

echo "mkdir"
pssh -i -h ${ip_file} "mkdir -p /users/${user_name}/projects/cloudlab_script"

echo "scp"
for line in "${lines[@]}"; do
	scp ./my_repo.tar ${line}:/users/${user_name}/projects/cloudlab_script
done

echo "tar"
pssh -i -h servers.txt "tar xvf /users/${user_name}/projects/cloudlab_script/my_repo.tar -C /users/${user_name}/projects/cloudlab_script"
    
echo "rm my_repo.tar on each node"
pssh -i -h servers.txt "rm /users/${user_name}/projects/cloudlab_script/my_repo.tar"

#echo "init"
#pssh -i -h ${ip_file} "bash ${project_dir}/init.sh"

rm my_repo.tar

#!/bin/bash

echo "CHECK servers.txt file"
echo "TO GET MOST RECENT SERVERS, RUN 'python inventory.py'"
echo "It will start in 3 seconds"
for i in {3..1}; do
    echo $i
    sleep 1
done

echo "read servers.txt file"
while IFS= read -r line; do
    lines+=("$line")
    done < ${ip_file}

for line in "${lines[@]}"; do
    echo "$line"
done

pscp -h servers.txt hosts_detail.txt /users/gangmuk/projects/cloudlab_script/hosts_detail.txt

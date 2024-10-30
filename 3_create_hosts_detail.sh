#!/bin/bash


ip_file=servers.txt

while IFS= read -r line; do
    lines+=("$line")
    done < ${ip_file}

touch qwer
mv qwer hosts_detail.txt
#echo > hosts_detail.txt
for host in "${lines[@]}"; do
    echo "$host"
	hostname=$(ssh ${host} "echo \$HOSTNAME")

	IFS='.'
	for element in $hostname; do
	  nodename="$element"
	  break  # Exit the loop after the first iteration
	done
	IFS=$' \t\n'
	echo "* host: ${host}"
	echo "* hostname: ${hostname}"
	echo "* nodename: $nodename"
	if [ ${nodename} == "node0" ]
	then
		nodename=master${nodename}
		ssh ${host} ifconfig | grep -m 1 'inet'  | tr -s ' ' | cut -d " " -f 3 | sed "s/$/   ${hostname}   ${nodename}/" >> hosts_detail.txt
	else
		nodename=worker${nodename}
		ssh ${host} ifconfig | grep -m 1 'inet'  | tr -s ' ' | cut -d " " -f 3 | sed "s/$/   ${hostname}   ${nodename}/" >> hosts_detail.txt
	fi

done

cat hosts_detail.txt

# for host in "${lines[@]}"; do
# 	scp hosts_detail.txt ${host}:/users/gangmuk/projects/cloudlab_script
# done
pscp -h servers.txt hosts_detail.txt /users/gangmuk/projects/cloudlab_script

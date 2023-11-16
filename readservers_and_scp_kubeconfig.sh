read -p "Did you check the servers.txt file? Press Enter to continue: " inp

ip_file=servers.txt
while IFS= read -r line; do
    lines+=("$line")
    done < ${ip_file}
for line in "${lines[@]}"; do
    echo "scp ~/.kube/config to $line"
    ssh ${line} mkdir -p $HOME/.kube
    scp ~/.kube/config  ${line}:~/.kube/config
done

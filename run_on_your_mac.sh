#!/bin/bash
#
# Set up every node in config.xml from your Mac, end to end.
#
# usage: ./run_on_your_mac.sh [--k8s]
#   --k8s   also install Kubernetes (node0 = master, other nodes = workers) and join the workers

usage () {
    echo "usage: $0 [--k8s]"
    echo "  --k8s   also install Kubernetes (node0 = master, others = workers)"
}

install_k8s=false
for arg in "$@"; do
    case $arg in
        --k8s) install_k8s=true ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $arg"; usage; exit 1 ;;
    esac
done

cd "$(dirname "$0")"
repo_dir=/users/gangmuk/projects/cloudlab_script

# Stop at the first failing step
run_step () {
    echo ""
    echo "==================== $1 ===================="
    shift
    if ! "$@"; then
        echo "FAILED: $*"
        exit 1
    fi
}

if [ ! -f config.xml ]; then
    echo "config.xml not found. Copy the cloudlab manifest into config.xml first."
    exit 1
fi

# The nodes get this repo through git clone, so local changes that are not pushed never reach them
git fetch -q 2>/dev/null
if [ -n "$(git status --porcelain --untracked-files=no)" ] || [ -n "$(git log @{u}.. --oneline 2>/dev/null)" ]; then
    echo "WARNING: this repo has uncommitted or unpushed changes. The nodes will NOT get them."
    read -p "Continue anyway? [y/N]: " inp
    if [ "$inp" != "y" ] && [ "$inp" != "Y" ]; then
        exit 1
    fi
fi

echo "install_k8s: ${install_k8s}"

run_step "ssh keys between nodes" ./1_ssh_copy.sh    # also writes servers.txt, master.txt, workers.txt
master=$(cat master.txt)

run_step "git clone" ./2_mkdir_gitclone.sh
if [ -x ./2.5_gitclone_private_repo.sh ]; then
    run_step "git clone private repos" ./2.5_gitclone_private_repo.sh
fi
run_step "hosts_detail.txt" ./3_create_hosts_detail.sh
run_step "bashrc and vimrc" ./4_setup_vimrc_and_bashrc.sh

# ./6_copy_gurobi_wls.sh

run_step "basic packages in node0 (${master})" \
    ssh ${master} "cd ${repo_dir} && bash install_basic_pkg_in_node0.sh"

# pyinfra runs from node0 against every node. accept-new: don't stop to ask about unknown host keys
run_step "pyinfra deploy to all nodes" \
    ssh ${master} "cd ${repo_dir} && ~/myenv/bin/pyinfra --data ssh_strict_host_key_checking=accept-new inventory.py deploy.py"

if [ "${install_k8s}" == true ]; then
    # Master and workers install in parallel. The workers' output is printed when they finish.
    echo ""
    echo "==================== kubernetes install (master + workers) ===================="
    ssh ${master} "cd ${repo_dir} && ./cloudlab_k8s_setup.sh master" &
    master_pid=$!
    pssh -t 0 -i -h workers.txt "cd ${repo_dir} && ./cloudlab_k8s_setup.sh worker"
    workers_status=$?
    wait ${master_pid}
    master_status=$?
    if [ ${master_status} -ne 0 ] || [ ${workers_status} -ne 0 ]; then
        echo "FAILED: kubernetes install (master: ${master_status}, workers: ${workers_status})"
        exit 1
    fi

    join_cmd=$(ssh ${master} "sudo kubeadm token create --print-join-command")
    if [ -z "${join_cmd}" ]; then
        echo "FAILED: could not get kubeadm join command from ${master}"
        exit 1
    fi
    run_step "join workers" pssh -t 0 -i -h workers.txt "sudo ${join_cmd}"

    echo ""
    ssh ${master} "kubectl get nodes -o wide"
fi

echo ""
echo "All done."

#!/bin/bash
#
# Set up every node in config.xml from your Mac, end to end. See AGENTS.md.
#
# usage: ./run_on_your_mac.sh [--k8s] [--no-disk] [--from STEP] [--only STEP]

STEPS="keys disk sync hosts dotfiles basic deploy k8s join verify"
K8S_STEPS="k8s join verify"

usage () {
    echo "usage: $0 [--k8s] [--no-disk] [--from STEP] [--only STEP]"
    echo "  --k8s         also install Kubernetes (node0 = master, others = workers)"
    echo "  --no-disk     skip formatting/mounting the extra disk (everything stays on the root disk)"
    echo "  --from STEP   start at STEP (to resume after a failure)"
    echo "  --only STEP   run only STEP"
    echo "  steps, in order: ${STEPS}"
    echo "    keys      ssh keys so all nodes can ssh to each other"
    echo "    disk      format + mount an unused disk at /mnt (mount_extra_disk.sh), link ~/projects -> /mnt/projects"
    echo "    sync      copy this repo to the nodes, git clone the other repos"
    echo "    hosts     build hosts_detail.txt and copy it to the nodes"
    echo "    dotfiles  bashrc and vimrc"
    echo "    basic     apt packages + python venv (/mnt/venv) in node0"
    echo "    deploy    pyinfra deploy.py from node0 to all nodes"
    echo "    k8s       kubernetes install, master and workers in parallel   (--k8s)"
    echo "    join      join the workers to the master                       (--k8s)"
    echo "    verify    verify_k8s.sh on the master                           (--k8s)"
}

install_k8s=false
mount_disk=true
from_step=""
only_step=""
while [ $# -gt 0 ]; do
    case $1 in
        --k8s) install_k8s=true ;;
        --no-disk) mount_disk=false ;;
        --from) from_step=$2; shift ;;
        --only) only_step=$2; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1"; usage; exit 1 ;;
    esac
    shift
done
for s in ${from_step} ${only_step}; do
    if ! echo " ${STEPS} " | grep -q " ${s} "; then
        echo "Unknown step: ${s}"; usage; exit 1
    fi
    # Asking for a kubernetes step implies --k8s
    echo " ${K8S_STEPS} " | grep -q " ${s} " && install_k8s=true
done

cd "$(dirname "$0")"
repo_dir=/users/gangmuk/projects/cloudlab_script

# Should this step run, given --from / --only / --k8s?
reached=false
[ -z "${from_step}" ] && reached=true
want () {
    [ "$1" == "${from_step}" ] && reached=true
    if echo " ${K8S_STEPS} " | grep -q " $1 " && [ "${install_k8s}" != true ]; then
        return 1
    fi
    if [ -n "${only_step}" ]; then
        [ "$1" == "${only_step}" ]
        return
    fi
    [ "${reached}" == true ]
}

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

echo "install_k8s: ${install_k8s}, mount_disk: ${mount_disk}, from: ${from_step:-start}, only: ${only_step:-all}"

# servers.txt, master.txt, workers.txt from config.xml
python inventory.py > /dev/null || { echo "FAILED: python inventory.py"; exit 1; }
master=$(cat master.txt)

if want keys; then
    run_step "keys: ssh keys between nodes" ./1_ssh_copy.sh
fi

if want disk; then
    if [ "${mount_disk}" == true ]; then
        pscp -h servers.txt mount_extra_disk.sh /tmp/mount_extra_disk.sh > /dev/null
        run_step "disk: mount extra disk at /mnt" pssh -t 0 -i -h servers.txt "sudo bash /tmp/mount_extra_disk.sh"
    else
        # /mnt stays on the root disk, but repos and the venv still go there
        run_step "disk: skipped, using /mnt on the root disk" pssh -i -h servers.txt \
            "sudo mkdir -p /mnt/projects && sudo chown \$USER /mnt /mnt/projects"
    fi
    # ~/projects points to /mnt/projects so /users/gangmuk/projects paths keep working
    run_step "disk: link ~/projects to /mnt/projects" pssh -i -h servers.txt \
        "if [ ! -e ~/projects ]; then ln -s /mnt/projects ~/projects; elif [ ! -L ~/projects ]; then echo 'WARNING: ~/projects already exists, leaving it on the root disk'; fi"
fi

if want sync; then
    run_step "sync: copy this repo, clone other repos" ./2_mkdir_gitclone.sh
    if [ -x ./2.5_gitclone_private_repo.sh ]; then
        run_step "sync: clone private repos" ./2.5_gitclone_private_repo.sh
    fi
fi

if want hosts; then
    run_step "hosts: hosts_detail.txt" ./3_create_hosts_detail.sh
fi

if want dotfiles; then
    run_step "dotfiles: bashrc and vimrc" ./4_setup_vimrc_and_bashrc.sh
fi

# ./6_copy_gurobi_wls.sh

if want basic; then
    run_step "basic: packages and venv in node0 (${master})" \
        ssh ${master} "cd ${repo_dir} && bash install_basic_pkg_in_node0.sh"
fi

if want deploy; then
    # pyinfra runs from node0 against every node. accept-new: don't stop to ask about unknown host keys
    run_step "deploy: pyinfra to all nodes" \
        ssh ${master} "cd ${repo_dir} && /mnt/venv/bin/pyinfra --data ssh_strict_host_key_checking=accept-new inventory.py deploy.py"
fi

if want k8s; then
    # Master and workers install in parallel. The workers' output is printed when they finish.
    echo ""
    echo "==================== k8s: install (master + workers) ===================="
    ssh ${master} "cd ${repo_dir} && ./cloudlab_k8s_setup.sh master" &
    master_pid=$!
    workers_status=0
    if [ -s workers.txt ]; then
        pssh -t 0 -i -h workers.txt "cd ${repo_dir} && ./cloudlab_k8s_setup.sh worker"
        workers_status=$?
    fi
    wait ${master_pid}
    master_status=$?
    if [ ${master_status} -ne 0 ] || [ ${workers_status} -ne 0 ]; then
        echo "FAILED: kubernetes install (master: ${master_status}, workers: ${workers_status})"
        exit 1
    fi
fi

if want join && [ -s workers.txt ]; then
    join_cmd=$(ssh ${master} "sudo kubeadm token create --print-join-command")
    if [ -z "${join_cmd}" ]; then
        echo "FAILED: could not get kubeadm join command from ${master}"
        exit 1
    fi
    run_step "join: workers join the master" pssh -t 0 -i -h workers.txt "sudo ${join_cmd}"
fi

if want verify; then
    run_step "verify: kubernetes cluster" ssh ${master} "cd ${repo_dir} && ./verify_k8s.sh"
fi

echo ""
echo "All done."

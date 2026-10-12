#!/bin/bash

ip_file=servers.txt
project_dir=/users/gangmuk/projects

# Copy this repo from the Mac (not git clone), so local edits reach the nodes without a push.
# Includes the gitignored per-cluster files (config.xml, servers.txt, ...). Not a git repo on the nodes.
sync_this_repo () {
    pids=()
    while IFS= read -r host; do
        (
            ssh ${host} "mkdir -p ${project_dir}/cloudlab_script" &&
            rsync -az --delete --exclude .git --exclude .DS_Store --exclude __pycache__ \
                --exclude NotUsed --exclude not_being_used \
                ./ ${host}:${project_dir}/cloudlab_script/ &&
            echo "synced cloudlab_script to ${host}"
        ) &
        pids+=($!)
    done < ${ip_file}
    status=0
    for pid in "${pids[@]}"; do
        wait ${pid} || status=1
    done
    return ${status}
}

# Clone the repo, or pull it if it is already there (so this script can be re-run)
clone_or_pull () {
    url=$1
    dir=${project_dir}/$2
    pssh -t 0 -i -h ${ip_file} "if [ -d ${dir}/.git ]; then git -C ${dir} pull --ff-only || echo 'WARN: could not pull ${dir}'; else git clone ${url} ${dir}; fi"
}

sync_this_repo || exit 1

# clone_or_pull https://github.com/ServiceLayerNetworking/slate-benchmark.git slate-benchmark
# pscp -h ${ip_file} config.xml ${project_dir}/slate-benchmark

# clone_or_pull https://github.com/ServiceLayerNetworking/DeathStarBench.git DeathStarBench

# clone_or_pull https://github.com/gangmuk/client.git client

# clone_or_pull https://github.com/ServiceLayerNetworking/SLATE.git SLATE

clone_or_pull https://github.com/gangmuk/LLM_placement_solver.git LLM_placement_solver

clone_or_pull https://github.com/gangmuk/aibrix-gangmuk.git aibrix-gangmuk

clone_or_pull https://github.com/gangmuk/all-the-scripts.git all-the-scripts

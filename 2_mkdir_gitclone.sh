#!/bin/bash

ip_file=servers.txt
project_dir=/users/gangmuk/projects

# Clone the repo, or pull it if it is already there (so this script can be re-run)
clone_or_pull () {
    url=$1
    dir=${project_dir}/$2
    pssh -t 0 -i -h ${ip_file} "if [ -d ${dir}/.git ]; then git -C ${dir} pull --ff-only || echo 'WARN: could not pull ${dir}'; else git clone ${url} ${dir}; fi"
}

clone_or_pull https://github.com/gangmuk/cloudlab_script.git cloudlab_script
pscp -h ${ip_file} config.xml ${project_dir}/cloudlab_script

# clone_or_pull https://github.com/ServiceLayerNetworking/slate-benchmark.git slate-benchmark
# pscp -h ${ip_file} config.xml ${project_dir}/slate-benchmark

# clone_or_pull https://github.com/ServiceLayerNetworking/DeathStarBench.git DeathStarBench

# clone_or_pull https://github.com/gangmuk/client.git client

# clone_or_pull https://github.com/ServiceLayerNetworking/SLATE.git SLATE

clone_or_pull https://github.com/gangmuk/LLM_placement_solver.git LLM_placement_solver

clone_or_pull https://github.com/gangmuk/aibrix-gangmuk.git aibrix-gangmuk

clone_or_pull https://github.com/gangmuk/all-the-scripts.git all-the-scripts

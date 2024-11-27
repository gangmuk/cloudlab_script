#!/bin/bash

ip_file=servers.txt
project_dir=/users/gangmuk/projects

pssh -i -h ${ip_file} "git clone https://github.com/gangmuk/cloudlab_script.git ${project_dir}/cloudlab_script"
pscp -h servers.txt config.xml ${project_dir}/cloudlab_script

pssh -i -h ${ip_file} "git clone https://github.com/ServiceLayerNetworking/slate-benchmark.git ${project_dir}/slate-benchmark"
pscp -h servers.txt config.xml ${project_dir}/slate-benchmark

pssh -i -h ${ip_file} "git clone https://github.com/ServiceLayerNetworking/DeathStarBench.git ${project_dir}/DeathStarBench"

pssh -i -h ${ip_file} "git clone https://github.com/gangmuk/client.git ${project_dir}/client"

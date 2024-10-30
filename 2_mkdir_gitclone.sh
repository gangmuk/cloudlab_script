#!/bin/bash

ip_file=servers.txt
project_dir=/users/gangmuk/projects

pssh -i -h ${ip_file} "git clone https://github.com/gangmuk/cloudlab_script.git ${project_dir}/cloudlab_script"
pscp -h servers.txt config.xml ${project_dir}/cloudlab_script

pssh -i -h ${ip_file} "git clone https://github.com/ServiceLayerNetworking/slate-benchmark.git ${project_dir}/slate-benchmark"
pscp -h servers.txt config.xml ${project_dir}/slate-benchmark

pssh -i -h ${ip_file} "git clone https://github.com/ServiceLayerNetworking/DeathStarBench.git ${project_dir}/DeathStarBench"
<<<<<<< HEAD

pssh -i -h ${ip_file} "git clone https://github.com/gangmuk/client.git ${project_dir}/client"
=======
>>>>>>> 37acbf721682502b69a1b4a4f20aca5f67ee2c2a

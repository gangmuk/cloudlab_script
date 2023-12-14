#!/bin/bash

ip_file=servers.txt
project_dir=/users/gangmuk/projects/cloudlab_script

python inventory.py

#if [ -d ${project_dir} ]
#then
#    echo "${project_dir} exists"
#    echo "exit..."
#    exit
#else
#    echo "mkdir ${project_dir}"
#    pssh -i -h ${ip_file} "mkdir -p ${project_dir}""
#fi

pssh -i -h ${ip_file} "git clone https://github.com/gangmuk/cloudlab_script.git ${project_dir}"

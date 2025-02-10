#!/bin/bash

python inventory.py

echo "read servers.txt file"

source_file=change_cpu_governor.sh
destination_file=/users/gangmuk/projects/${source_file}

pscp -h servers.txt ${source_file} ${destination_file}

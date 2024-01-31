#!/bin/bash

echo "Kill pyinfra process in all servers."

pssh -i -h servers.txt pkill -f "pyinfra"

#psch -h servers.txt <file> /path/to/client_target_dir

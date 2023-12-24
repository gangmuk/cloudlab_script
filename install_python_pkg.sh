ip_file=servers.txt
project_dir=/users/gangmuk/projects/cloudlab_script
directory_to_add="/users/gangmuk/.local/bin"

pssh -i -h ${ip_file} "sudo apt-get install pip -y"

path_add="export PATH=\$PATH:$directory_to_add"
pssh -i -h ${ip_file} "${path_add} >> ~/.bashrc"

pssh -i -h ${ip_file} "source ~/.bashrc"

pssh -i -h ${ip_file} "pip install -r ${project_dir}/requirements.txt"

# Check if the directory exists
#if [ -d "$directory_to_add" ]; then
#    # Add the directory to the PATH in ~/.bashrc
#    echo "export PATH=\$PATH:$directory_to_add" >> ~/.bashrc
#    echo "Directory added to PATH. Restart your terminal or run 'source ~/.bashrc'."
#else
#    echo "Error: Directory does not exist."
#fi

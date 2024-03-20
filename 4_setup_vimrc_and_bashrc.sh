## Bash
bashrc='~/.bashrc'

# Add PATH
pssh -i -h servers.txt "echo 'export PATH=\$PATH:/users/gangmuk/.local/bin' >> ${bashrc}"
# SLATE/sh path
pssh -i -h servers.txt "echo 'export PATH=\$PATH:/users/gangmuk/projects/SLATE/sh' >> ${bashrc}"

# bash history
pssh -i -h servers.txt "echo 'HISTSIZE=50000' >> ${bashrc}"
pssh -i -h servers.txt "echo 'HISTFILESIZE=50000' >> ${bashrc}"

# alias
kubectl=\'kubectl\'
pssh -i -h servers.txt "echo alias k=${kubectl} >> ${bashrc}"

pssh -i -h servers.txt "source ~/.bashrc"

## Vim
pscp -h servers.txt ~/.vimrc /users/gangmuk/

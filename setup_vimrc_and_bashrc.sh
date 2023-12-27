## Bash
bashrc='~/.bashrc'

# Add PATH
echo 'export PATH=$PATH:/users/gangmuk/.local/bin' >> ${bashrc}

# bash history
echo 'HISTSIZE=50000' >> ${bashrc}
echo 'HISTFILESIZE=50000' >> ${bashrc}

# alias
kubectl=\'kubectl\'
echo alias k=${kubectl} >> ${bashrc}

source ~/.bashrc


## Vim
pscp -h servers.txt ~/.vimrc /users/gangmuk/


# zshrc='~/.zshrc'
# pssh -i -h servers.txt "echo 'bash' >> ${zshrc}"

bashrc='~/.bashrc'
pssh -i -h servers.txt "echo 'ulimit -n 1048576' >> ${bashrc}"

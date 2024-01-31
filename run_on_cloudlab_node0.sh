./install_basic_pkg_in_node0.sh

pyinfra inventory.py deploy.py

# luasocket for wrk2
sudo luarocks install luasocket

# tinygo
wget https://github.com/tinygo-org/tinygo/releases/download/v0.30.0/tinygo_0.30.0_amd64.deb
sudo dpkg -i tinygo_0.30.0_amd64.deb

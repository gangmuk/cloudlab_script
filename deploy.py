from pyinfra.operations import apt, files, server, python, git, ssh
from pyinfra import host, config
from pyinfra.facts.server import LinuxDistribution, LinuxName, OsVersion, Users
import os
from pathlib import Path
import subprocess
import utils


# Path to ssh key for repos
#git_ssh_key = "files/setup/git_ssh_key"

# Packages to install
packages = [
    "cmake",
    "htop",
    "vim",
    "git",
#    "maven",
#    "python2",
    "protobuf-compiler",
    "libunwind-dev",
    "libevent-dev",
    "pkg-config",
    "libssl-dev",
    "libgflags-dev",
    "luarocks",
    "jq",
    "pssh",
]

# Workloads to generate
#workloads = ["load", "a"]


distribution_name = host.get_fact(LinuxDistribution)["name"]
if distribution_name != "Ubuntu":
    raise Exception(
        "This deploy script only works on Ubuntu unlike {}", distribution_name
    )

# Install packages
apt.packages(
    packages,
    latest=True,
    upgrade=True,
    update=True,
    _sudo=True
    # user=username,
)

server.shell(
    name='Change to tmp directory',
    commands='cd ~'
)

# WRK2
server.shell(
	name='Install luasocket',
	commands='sudo luarocks install luasocket'
)
server.shell(
    name='make wrk2',
    commands='make -C /users/gangmuk/projects/DeathStarBench/wrk2'
)

# GO
server.shell(
    name='Download Go',
    commands='wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz'
)
server.shell(
    name='Extract Go',
    commands='sudo tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz'
)
server.shell(
    name='Add Go to PATH',
    commands="echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc"
)

# TINYGO
server.shell(
    name='Download TinyGo',
    commands='wget https://github.com/tinygo-org/tinygo/releases/download/v0.30.0/tinygo_0.30.0_amd64.deb'
)
server.shell(
    name='Install TinyGo',
    commands='sudo dpkg -i tinygo_0.30.0_amd64.deb'
)
server.shell(
    name='Update PATH for TinyGo',
    commands="echo 'export PATH=$PATH:/usr/local/bin/tinygo' >> ~/.bashrc"
)

# ZELLIJ
zellij_url = "https://github.com/zellij-org/zellij/releases/download/v0.39.2/zellij-x86_64-unknown-linux-musl.tar.gz"
zellij_tar = "zellij-x86_64-unknown-linux-musl.tar.gz"
files.download(
    name="Download Zellij",
    src=zellij_url,
    dest=zellij_tar
)
server.shell(
    name="Extract Zellij",
    commands=[
        f"tar -xvf {zellij_tar}"
    ]
)
server.shell(
    name="Install Zellij",
    commands=[
        "chmod +x zellij",
        "sudo mv zellij /usr/local/bin/"
    ]
)

# GIT CONFIG
server.shell(
    name="Update git config",
    commands=[
        "git config --global core.editor 'vim'",
        "git config --global user.name 'gangmuk@gmail.com'",
        "git config --global user.email 'gangmuk@gmail.com'",
        "git config --global pull.rebase true",
    ]
)


#username = utils.get_username()
#home_directory = f"/users/{username}"
#print(f"home_directory: {home_directory}")

# Setup ssh key
#files.put(
#    git_ssh_key,
#    f"{home_directory}/.ssh/id_rsa",
#    mode="0600",
#    create_remote_dir=True,
#    user=username,
#)

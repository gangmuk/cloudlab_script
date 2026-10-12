from pyinfra.operations import apt, files, server, python, git, ssh
from pyinfra import host, config
from pyinfra.facts.server import KernelVersion, LinuxDistribution, LinuxName, OsVersion, Users
import os
from pathlib import Path
import subprocess


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
    "graphviz",
    "stress",
    "linux-tools-common",
    # linux-tools/linux-cloud-tools for the running kernel are appended below
    "golang-easyjson",
]

# Workloads to generate
#workloads = ["load", "a"]


distribution_name = host.get_fact(LinuxDistribution)["name"]
if distribution_name != "Ubuntu":
    raise Exception(
        "This deploy script only works on Ubuntu unlike {}".format(distribution_name)
    )

kernel_version = host.get_fact(KernelVersion)
packages += [f"linux-tools-{kernel_version}", f"linux-cloud-tools-{kernel_version}"]

# Install packages
apt.packages(
    packages,
    latest=True,
    upgrade=True,
    update=True,
    _sudo=True
    # user=username,
)

# WRK2 (needs DeathStarBench, which 2_mkdir_gitclone.sh no longer clones)
#server.shell(
#	name='Install luasocket',
#	commands='sudo luarocks install luasocket'
#)
#server.shell(
#    name='make wrk2',
#    commands='make -C /users/gangmuk/projects/DeathStarBench/wrk2'
#)

# GO
# PATH for /usr/local/go/bin is set in bashrc_for_server
server.shell(
    name='Download Go',
    commands='wget -q -O /tmp/go1.21.6.linux-amd64.tar.gz https://go.dev/dl/go1.21.6.linux-amd64.tar.gz'
)
server.shell(
    name='Extract Go',
    commands='sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go1.21.6.linux-amd64.tar.gz'
)

# TINYGO
# The deb installs the tinygo binary into /usr/local/bin, which is already on PATH
server.shell(
    name='Download TinyGo',
    commands='wget -q -O /tmp/tinygo_0.30.0_amd64.deb https://github.com/tinygo-org/tinygo/releases/download/v0.30.0/tinygo_0.30.0_amd64.deb'
)
server.shell(
    name='Install TinyGo',
    commands='sudo dpkg -i /tmp/tinygo_0.30.0_amd64.deb'
)

# ZELLIJ
#zellij_url = "https://github.com/zellij-org/zellij/releases/download/v0.39.2/zellij-x86_64-unknown-linux-musl.tar.gz"
#zellij_tar = "zellij-x86_64-unknown-linux-musl.tar.gz"
#files.download(
#    name="Download Zellij",
#    src=zellij_url,
#    dest=zellij_tar
#)
#server.shell(
#    name="Extract Zellij",
#    commands=[
#        f"tar -xvf {zellij_tar}"
#    ]
#)
#server.shell(
#    name="Install Zellij",
#    commands=[
#        "chmod +x zellij",
#        "sudo mv zellij /usr/local/bin/"
#    ]
#)

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

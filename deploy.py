from pyinfra.operations import apt, files, server, python, git, ssh
from pyinfra import host, config
from pyinfra.facts.server import LinuxDistribution, LinuxName, OsVersion, Users
import os
from pathlib import Path
import subprocess
import utils


# Path to ssh key for repos
git_ssh_key = "files/setup/git_ssh_key"

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
]

# Workloads to generate
#workloads = ["load", "a"]

username = utils.get_username()
home_directory = f"/users/{username}"
print(f"home_directory: {home_directory}")

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

# Setup ssh key
files.put(
    git_ssh_key,
    f"{home_directory}/.ssh/id_rsa",
    mode="0600",
    create_remote_dir=True,
    user=username,
)

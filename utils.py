from pyinfra.operations import apt, files, server, python, git, ssh
from pyinfra import host, config
from pyinfra.facts.server import LinuxDistribution, LinuxName, OsVersion, Users
import os
from pathlib import Path
import subprocess

def get_env_variable(name):
    try:
        return os.environ[name]
    except KeyError:
        message = "Expected environment variable '{}' not set.".format(name)
        raise Exception(message)

def get_username():
    users = host.get_fact(Users)
    try:
        username = get_env_variable("USER")
        if username not in users:
            user = server.user(username, present=True, shell="/bin/bash", ensure_home=True, sudo=True)
        else:
            user = users[username]
    except:
        username = "makneee"
        user = server.user(username, present=True, shell="/bin/bash", ensure_home=True, sudo=True)
    return username

def disable_strict_host_key_checking():
    strict_host_key_checking = f"""
Host *
StrictHostKeyChecking no
"""

    ssh_config_path = Path.home() / '.ssh/config'
    ssh_config_path.parent.mkdir(parents=True, exist_ok=True)
    ssh_config = ''
    try:
        with open(ssh_config_path, 'r') as f:
            ssh_config = f.read()
    except:
        pass

    if strict_host_key_checking not in ssh_config:
        ssh_config += strict_host_key_checking
        
        with open(ssh_config_path, 'w+') as f:
            f.write(ssh_config)

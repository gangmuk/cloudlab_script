#!/bin/bash

sudo apt-get update -y
sudo apt-get install python3-pip -y
sudo apt-get install htop -y

sudo apt-get install python3-full -y
# /mnt is the extra disk (mount_extra_disk.sh). bashrc_for_server activates this venv.
python3 -m venv /mnt/venv
source /mnt/venv/bin/activate

# pyinfra 2.8 needs pkg_resources, which setuptools 81+ removed. The venv's default
# setuptools (59 on Ubuntu 22.04) is too old to find new wheels like zope_event, so pin it in between.
pip install "setuptools>=70,<81"
pip install -r /users/gangmuk/projects/cloudlab_script/requirements.txt

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!! RUN source ~/.bashrc !!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!"

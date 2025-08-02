#!/bin/bash

sudo apt-get update -y
# sudo apt-get upgrade -y
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::="--force-confold" --dry-run
sudo apt-get install python3-pip -y

sudo apt install python3-full
python3 -m venv ~/myenv
source ~/myenv/bin/activate
echo "source ~/myenv/bin/activate" >> ~/.bashrc

pip install -r /users/gangmuk/projects/cloudlab_script/requirements.txt

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!! RUN source ~/.bashrc !!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!"

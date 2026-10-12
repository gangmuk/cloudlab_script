#!/bin/bash

sudo apt-get update -y
sudo apt-get install python3-pip -y
sudo apt-get install htop -y

sudo apt-get install python3-full -y
python3 -m venv ~/myenv
source ~/myenv/bin/activate
grep -qxF "source ~/myenv/bin/activate" ~/.bashrc || echo "source ~/myenv/bin/activate" >> ~/.bashrc

pip install -r /users/gangmuk/projects/cloudlab_script/requirements.txt

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!! RUN source ~/.bashrc !!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!"

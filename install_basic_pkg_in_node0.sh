#!/bin/bash

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install pip -y

pip install -r /users/gangmuk/projects/cloudlab_script/requirements.txt

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!! RUN source ~/.bashrc !!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!"

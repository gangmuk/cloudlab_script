#!/bin/bash

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install pip -y

sudo apt install python3-full
python3 -m venv ~/myenv
source ~/myenv/bin/activate

pip install -r /users/gangmuk/projects/cloudlab_script/requirements.txt

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!! RUN source ~/.bashrc !!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!"

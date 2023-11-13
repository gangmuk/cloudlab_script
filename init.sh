sudo apt-get upgrade -y
sudo apt-get update
python get-pip.py
sudo apt-get install python3-pip -y
pip install -r requirements.txt
pyinfra inventory.py deploy.py

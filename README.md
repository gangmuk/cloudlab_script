# cloudlab_script


1. Create a cluster in cloudlab (start experiment)
2. git clone [this repo] in YOUR LOCAL MACHINE (e.g., MacBook).
3. run cloudlab_script/ssh_copy.sh in YOUR LOCAL MACHINE (e.g., MacBook). It will ask yes/no for authentication and ask Enter/Enter/Enter for ssh-keygen.
4. ssh to node 1 in cloud lab cluster.
5. run ```ssh-keygen``` command to generate key in node 1.
6. vi ~/.ssh/id_rsa.pub, and copy the pub key and add it to your github account (SSH and GPG Key in setting).
7. mkdir projects; cd projects; git clone [this repo]
8. git pull this repo (cloudlab_script) in node 1.
9. sudo apt-get upgrade -y
10. sudo apt-get update
11. python get-pip.py
12. sudo apt-get install python3-pip -y
13. pip install -r requirements.txt (it requires logout and login)
14. Copy cluster manifest from cloudlab gui and paste it to the **config.xml** file in the node 1 in cloud lab cluster
15. pyinfra inventory.py deploy.py


## Common error
- ValueError blah blah blah in gevent version error.
    - Simple solution is uninstall greenlet, gevent, pyinfra and install all of them again. The order might have to be greenlet, gevent and then pyinfra.

- ssh authentication issue while running pyinfra.
```bash
--> Connecting to hosts...
    No host key for apt063.apt.emulab.net found in known_hosts
    No host key for apt041.apt.emulab.net found in known_hosts
    No host key for apt055.apt.emulab.net found in known_hosts
    No host key for apt044.apt.emulab.net found in known_hosts
    [apt063.apt.emulab.net] Authentication error () (Authentication failed.)
    [apt041.apt.emulab.net] Authentication error () (Authentication failed.)
    [apt055.apt.emulab.net] Authentication error () (Authentication failed.)
    [apt049.apt.emulab.net] Authentication error () (Authentication failed.)
    [apt044.apt.emulab.net] Authentication error () (Authentication failed.)
--> pyinfra error: No hosts remaining!
```

Solution: uninstall greenlet and gevent and pyinfra and reinstall... Don't specify the versions for greenlet and gevent package.


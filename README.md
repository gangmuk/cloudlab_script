# cloudlab_script


1. Create a cluster in cloudlab (start experiment)
2. ```git clone [this repo]``` in YOUR LOCAL MACHINE (e.g., MacBook).
3. run ```cloudlab_script/ssh_copy.sh``` in **YOUR LOCAL MACHINE (e.g., MacBook)**. It will ask yes/no for authentication and ask Enter/Enter/Enter for ssh-keygen.
4. Now you should be able to ssh node1 at node 0
5. ```mkdir projects```; ```cd projects```; ```git clone [this repo]``` in **YOUR LOCAL MACHINE (e.g., MacBook)**.
6. ```sudo apt-get upgrade -y```
7. ```sudo apt-get update```
8. ```python get-pip.py```
9. ```sudo apt-get install python3-pip -y```
10. ```pip install -r requirements.txt``` (it requires logout and login)
11. Copy cluster manifest from cloudlab gui and paste it to the **config.xml** file in **cloud lab node 0**
12. ```pyinfra inventory.py deploy.py```

#### ssh-keygen
4. ssh to node 1 in cloud lab cluster.
5. run ```ssh-keygen``` command to generate key in node 1.
6. vi ~/.ssh/id_rsa.pub, and copy the pub key and add it to your github account (SSH and GPG Key in setting).

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


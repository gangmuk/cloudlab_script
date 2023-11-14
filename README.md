# cloudlab_script

local_machine: **YOUR LOCAL MACHINE (e.g., MacBook)**. 
client:  **node 0 in cloudlab**.

1. Create a cluster in cloudlab (start experiment)
2. [local_machine] Copy cluster manifest from cloudlab gui and paste it to the **config.xml** file in **cloud lab node 0**
3. [local_machine] ./ssh_copy.sh
4. [local_machine] ./mkdir_gitclone.sh
5. [local_machine] ssh to node 0 in cloud lab cluster.
6. [clinet] ```pip install -r requirements.txt``` (it requires logout and login)
7. [clinet] ```pyinfra inventory.py deploy.py```
8. READY TO RUN ```cloudlab_k8s_setup.sh``` (It is another separate job...)

---
5. run ```ssh-keygen``` command to generate key in node 1.
6. vi ~/.ssh/id_rsa.pub, and copy the pub key and add it to your github account (SSH and GPG Key in setting).
7. ```git clone [this repo]``` in **YOUR LOCAL MACHINE (e.g., MacBook)**.
8. run ```cloudlab_script/ssh_copy.sh```. It will ask yes/no for authentication and ask Enter/Enter/Enter for ssh-keygen.
9. Now you should be able to ssh node1 at node 0
10. ```mkdir projects```; ```cd projects```; ```git clone [this repo]``` in **node 0 in cloudlab**.
11. ```sudo apt-get upgrade -y```
12. ```sudo apt-get update```
13. ```python get-pip.py```
14. ```sudo apt-get install python3-pip -y```


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


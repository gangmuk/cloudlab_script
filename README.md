# cloudlab_script

1. You need to copy manifest from cloudlab gui and paste to the **config.xml** file in the local machine. You should run pyinfra script in the same path where this config.xml is located. config.xml is needed to get ip_adress of all cloudlab nodes. However, it requires you to copy only one manifest of one server (it does not matter which node it is) not all manifest from all server.

2. Install required python packages (run on your local machine. e.g., mac)
    ```bash
    pip install requirements.txt
    ```

3. Run pyinfra for inventory.py and for deploy.py (run on your local machine)
    ```bash
    pyinfra inventory.py deploy.py
    ```

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

solution: I couldn't find it yet...
It is related to **Host * StrictHostKeyChecking No** in ~/.ssh/config.
However, it is not working even with that config.  

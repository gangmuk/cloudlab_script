# cloudlab_script

[local machine]: YOUR LOCAL MACHINE (e.g., MacBook)
[client]: Node<i> in cloudlab


## cloudlab node set up
1. Create a cluster in cloudlab (start experiment)
2. [local machine] Copy cluster manifest from cloudlab gui and paste it to the **config.xml** file.
3. [local machine] ```./ssh_copy.sh```
   - Run inventory.py (it reads config.xml file and writes serves.txt file)
   - Generate ssh-key on each node in the cloud lab cluster.
   - cat all cloud lab ssh-key and write it to all_keys.txt in the [local machine].
   - scp all_keys.txt from [local machine] to all clients (cloud lab nodes)
   - Append all_keys.txt in the clients to its authorized_keys
5. [local machine] ```./mkdir_gitclone.sh```
   - Create projects directory in the clients
   - git clone this repo(cloudlab_script) in /users/gangmuk/projects path
7. [local machine] ```./create_hosts_detail.sh```
   - hosts_detail.txt which will be used by cloudlab_k8s_setup.sh
   - You have to modify this file to specify the k8s nodes.
   - Remove nodes in hosts_detail.txt which you don't want to include in k8s cluster.
9. [local machine] ssh node0 in cloud lab cluster.
10. [client] ```./install_python_pkg.sh``` and ```source ~/.bashrc```
    - install pip
    - run pip install -r requirements.txt
    - add path to .bashrc
12. [client] ```pyinfra inventory.py deploy.py```
    - This is for pyinfra basically
    - install some basic linux packages in all client nodes.
14. READY TO RUN ```cloudlab_k8s_setup.sh``` (It is another separate job...)

---
## cloudlab_k8s_setup.sh
1. [client] ```./cloudlab_k8s_setup.sh```
   - Is this MASTER NODE? [Y/N]:
2. If it is worker node, you are supposed to run ```sudo kubeadm join ...``` command to join the cluster. You can get the full command by running ```./get_join_command.sh in **master** node.

---
## istio multi-primary cluster on different network
Run ```./cloudlab_script/install_istio_bookinfo.sh```
reference: https://istio.io/latest/docs/setup/install/multicluster/multi-primary_multi-network/
1. Set the default network for cluster1
2. Configure cluster1 as a primary
3. Install the east-west gateway in cluster1
4. Expose services in cluster1
5. Set the default network for cluster2
6. Configure cluster2 as a primary
7. Install the east-west gateway in cluster2
8. Expose services in cluster2
9. Enable Endpoint Discovery

---
## metallb
Why do we need metallb?
    metallb doc: https://metallb.universe.tf
How to give external-ip to LoadBalancer service using metallb 
    useful blog post: https://mvallim.github.io/kubernetes-under-the-hood/documentation/kube-metallb.html

- To give external ip to load-balancer type service (istio ingressgateway or eastwest gateway in our case), so that we can access it from outside world.
	EXTERNAL-IP is empty. We want to fill
	```bash
	$ k get svc -n istio-system
	NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                                      AGE
	istio-ingressgateway   LoadBalancer   10.105.119.53   <pending>     15021:31750/TCP,80:30494/TCP,443:30676/TCP   11h
	istiod                 ClusterIP      10.102.10.213   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP        11h
	```

RUN ```cloudlab_script/metallb/metallb.sh```
It is not able to access external-ip from outside...
It works inside the network

---

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


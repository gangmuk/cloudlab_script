# cloudlab_script

[local_machine]: **YOUR LOCAL MACHINE (e.g., MacBook)**. 
[client]: **Node 0 in cloudlab**.

1. Create a cluster in cloudlab (start experiment)
2. [local_machine] Copy cluster manifest from cloudlab gui and paste it to the **config.xml** file.
3. [local_machine] ./ssh_copy.sh
4. [local_machine] ./mkdir_gitclone.sh
5. [local_machine] ./get_ip.sh
6. [local_machine] ssh to node 0 in cloud lab cluster.
7. [clinet] ```pip install -r requirements.txt``` (it requires logout and login)
8. [clinet] ```pyinfra inventory.py deploy.py```
9. READY TO RUN ```cloudlab_k8s_setup.sh``` (It is another separate job...)

---
# istio multi-primary cluster on different network
reference: https://istio.io/latest/docs/setup/install/multicluster/multi-primary_multi-network/

	Set the default network for cluster1
	Configure cluster1 as a primary
	Install the east-west gateway in cluster1
	Expose services in cluster1
	Set the default network for cluster2
	Configure cluster2 as a primary
	Install the east-west gateway in cluster2
	Expose services in cluster2
	Enable Endpoint Discovery

---
# metallb
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

1. kubectl edit configmap -n kube-system kube-proxy
2. change strictARP to true (the script below automates the process)
    ```bash
	kubectl get configmap kube-proxy -n kube-system -o yaml | \
	sed -e "s/strictARP: false/strictARP: true/" | \
	kubectl apply -f - -n kube-system
	```
3. install metallb
	```bash
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
	```
4. Add metallb namespace
    xxxxxxxxxxxxxxxxxxxx
	namespace yaml file
	```yaml
	apiVersion: v1
	kind: Namespace
	metadata:
	  name: metallb-system
	  labels:
		app: metallb
	```
    xxxxxxxxxxxxxxxxxxxx
5. create configmap for metallb to assign a range of ip addresses that will be used by metallb
    ```bash
    kubectl apply -f https://raw.githubusercontent.com/mvallim/kubernetes-under-the-hood/master/metallb/metallb-config.yaml
    ```
	or
	```bash
	kubectl apply -f metallb_config.yaml
	```
	filename: metallb_config.yaml
	```yaml
	apiVersion: v1
	kind: ConfigMap
	metadata:
		namespace: metallb-system
		name: config
	data:
		config: |
			address-pools:
			- name: default
			  protocol: layer2
			  addresses:
			  - 192.168.2.2-192.168.2.125
	```
    The last line (addresses) can be changed. These ip addresses will be given to LoadBalancer as external-ip.
6. Deploy LoadBalancer service or Restart existing LoadBalancer (ingress gateway or eastwest gateway)

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


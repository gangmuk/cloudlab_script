# AGENTS.md: setting up a CloudLab cluster

You are running on the user's Mac, in this repo. The user has just reserved CloudLab machines,
pasted the experiment manifest into `config.xml`, and asked you to set them up. Everything is
driven from the Mac over ssh. You never need to log in to a node by hand.

The scripts are tested and do the work. Your job is to run them in the right order, make
the decisions that need judgment (mainly the disk), check that each step worked, and
fix things when they break.

## Safety rules (read first)

1. **Only touch the nodes in the current `config.xml`.** The user may have other clusters with
   experiments running. Never ssh to hosts from an old `servers.txt`, `hosts_detail.txt` or
   anything else that doesn't come from the current `config.xml`. If you are unsure which
   machines are fresh, ask.
2. **Disk formatting needs the user's explicit OK.** Always do the dry run (step 2 below), show
   the user which disk each node would use, and wait for a yes. If they say no, use `--no-disk`.
   - **Never touch the root filesystem or the disk it lives on.**
   - Never weaken the checks in `mount_extra_disk.sh` to force a disk, and never pass a disk
     name by hand.
   - The choice is per node. On a node with no usable disk, `mount_extra_disk.sh` leaves `/mnt`
     on the root disk and the run goes on. Don't switch the whole run to `--no-disk` because some
     nodes have no spare disk; just report which nodes have none.
3. **Don't use `/proj`.** Repos go to `/mnt/projects` on each node (linked from `~/projects`).
4. **Never print secrets.** `CR_PAT` is a GitHub token. Don't echo it, and don't show
   `.git/config` of private clones.
5. **No git push is needed to run anything.** This repo reaches the nodes through rsync from
   the Mac, so your local edits are used right away. Commit or push only if the user asks.
6. **The Kubernetes steps are not safe to repeat** on a node that already has a cluster (see
   Known failures). Every other step can be re-run.

## Inputs

- **`config.xml`** (required): the CloudLab manifest, pasted by the user. It is gitignored.
  If the user gives only hostnames, get it from node0: `ssh <user>@<node0 host> geni-get manifest > config.xml`.
  Before replacing a `config.xml` for another cluster, keep it as `config_<experiment>.xml` (also gitignored).
  `python inventory.py` reads it and writes:
  - `servers.txt`: every node, as `user@host`
  - `master.txt`: node0, the Kubernetes master
  - `workers.txt`: all other nodes
- **`GITHUB_ACCOUNT` and `CR_PAT` env vars** (optional): needed only for private repos
  (`2.5_gitclone_private_repo.sh`). That file is gitignored, so it may only exist on the
  user's Mac. If the vars are missing, the script prints a message and skips; the run goes on.
  Ask the user whether private repos are needed.
- **Whether to install Kubernetes.** Default is no. Use `--k8s` only if the user asks.

## Mac prerequisites

- `pssh`, `pscp` and `rsync` must be on PATH.
- `python` must have `bs4` and `lxml`.
- `~/.ssh/config` must accept new host keys, e.g. `Host *` with `StrictHostKeyChecking no`.
  Fresh nodes are always unknown hosts, and pssh cannot answer a prompt.

Check quickly:

```
which pssh pscp rsync python && python -c "import bs4, lxml" && grep -i stricthostkeychecking ~/.ssh/config
```

## Procedure

1. **Read the manifest and set up ssh keys.**
   ```
   python inventory.py            # prints node0..nodeN and their hostnames; check this matches what the user expects
   ./run_on_your_mac.sh --only keys
   ```

2. **Disk dry run.** This changes nothing. Show the output to the user and ask before going on.
   ```
   pscp -h servers.txt mount_extra_disk.sh /tmp/mount_extra_disk.sh
   pssh -i -h servers.txt "sudo bash /tmp/mount_extra_disk.sh --dry-run"
   ```
   For each node it prints:
   - the root disk, which it will never touch
   - the candidate disks: whole disks, at least 50 GB, with no partitions, no filesystem and
     nothing mounted
   - the one it selected (SSD/NVMe before HDD, then the largest)

   Hardware differs by CloudLab type: `sdb` on c6420, `nvme*` on r6615, sometimes none.
   - Single-disk types (e.g. UMass rs620, and some c6420 nodes) get no candidate, though the root
     disk has ~800 GB unpartitioned. CloudLab's `/usr/local/etc/emulab/mkextrafs.pl` could make a
     partition there, but that edits the root disk's partition table: only with the user's
     explicit OK, never on your own. When the user was asked (Oct 2026), they chose `--no-disk`.
   For context, `lsblk -o NAME,SIZE,TYPE,ROTA,MOUNTPOINT,MODEL` on a node is useful.

3. **Run the rest** in the background, with output to a log. Watch for `FAILED` and `====` step headers.
   ```
   ./run_on_your_mac.sh --from disk [--k8s] [--no-disk] > /tmp/cloudlab_run.log 2>&1
   ```
   - Add `--no-disk` if the user declined formatting.
   - This takes a while: package installs on every node, plus Kubernetes if `--k8s`.
   - If you don't need private repos, unset the token vars:
     `env -u GITHUB_ACCOUNT -u CR_PAT ./run_on_your_mac.sh ...`

4. **If a step fails:** read the log, fix the cause (check Known failures first), then resume
   from that step with `--from STEP`. Run `./run_on_your_mac.sh --help` for the step names.

5. **Verify** (next section) and report to the user. Include:
   - which disk was mounted on each node
   - which repos are where
   - Kubernetes status, if installed
   - anything that was skipped or fixed

## Steps

Run `./run_on_your_mac.sh --help` for the step names. The default order is:

| step | what it does | where | check that it worked |
|---|---|---|---|
| `keys` | `1_ssh_copy.sh`: an ssh key on each node (an existing one is kept); those keys plus `extra_authorized_keys.txt` (the user's Delta and Delta AI login nodes) added to every node's `~/.ssh/authorized_keys2`, skipping keys already there. Safe to re-run | all | `pssh -i -h servers.txt "ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new $(head -1 master.txt) hostname"` |
| `disk` | `mount_extra_disk.sh` formats and mounts the chosen disk at `/mnt` (adds an fstab entry with `nofail`), then links `~/projects` to `/mnt/projects`. With `--no-disk`, `/mnt` stays on the root disk | all | `pssh -i -h servers.txt "findmnt /mnt; ls -ld ~/projects"` |
| `sync` | `2_mkdir_gitclone.sh`: rsyncs this repo (including `config.xml`) to `~/projects/cloudlab_script`, and git clones or pulls the other repos. Then `2.5_gitclone_private_repo.sh` if present | all | `pssh -i -h servers.txt "ls ~/projects"` |
| `hosts` | `3_create_hosts_detail.sh`: writes `hosts_detail.txt` (public IP, FQDN, master/worker name) and copies it to the nodes | Mac + all | `cat hosts_detail.txt`; the IPs should match the `<host ipv4=...>` entries in `config.xml` |
| `dotfiles` | copies `bashrc_for_server` to `~/.bashrc` and `vimrc_for_server` to `~/.vimrc`, overwriting both | all | |
| `basic` | `install_basic_pkg_in_node0.sh`: apt packages, venv at `/mnt/venv`, `requirements.txt` (pyinfra and others) | node0 | `ssh $(cat master.txt) /mnt/venv/bin/pyinfra --version` |
| `deploy` | pyinfra runs `deploy.py` from node0 against all nodes: apt packages, linux-tools for the running kernel, Go, TinyGo, git config | all | the log ends with `Errors: 0` for every host |
| `k8s` | `cloudlab_k8s_setup.sh master` on node0 and `worker` on the rest, in parallel: containerd (root `/mnt/containerd`), Docker (`/mnt/docker`), kubeadm/kubelet/kubectl v1.28. On the master also `kubeadm init`, Flannel and Helm | all | |
| `join` | gets a fresh join command from the master and runs it on the workers | workers | |
| `verify` | `verify_k8s.sh` on the master: all nodes `Ready`, and a pod on every worker can resolve cluster DNS (this crosses the pod network) | node0 | prints `PASS` |

Without `--k8s`, the last three steps are skipped. Naming a k8s step in `--from` or `--only`
turns `--k8s` on.

## Done means

- Every node: `/mnt` mounted, or `--no-disk` chosen deliberately.
- Every node: repos in `~/projects` (which points to `/mnt/projects`).
- The `deploy` step finished with `Errors: 0` on every host.
- With `--k8s`: `verify_k8s.sh` printed `PASS`.

## Known failures (already fixed; listed so you recognize them if they come back)

- **pyinfra crashes at startup** with `DistributionNotFound: The 'zope.event' distribution was
  not found`, or with `No module named 'pkg_resources'`.
  - Cause: pyinfra 2.8 needs `pkg_resources`. Ubuntu 22.04's default setuptools (59) is too old
    to find new-style wheels, and setuptools 81+ removed `pkg_resources`.
  - Fix: `install_basic_pkg_in_node0.sh` installs `setuptools>=70,<81`.
- **Helm not installed** (`[: false: unexpected operator`).
  - Cause: `get-helm-3` was run with `sh`, which is dash on Ubuntu.
  - Fix: it now runs with `bash`.
- **Join command with an empty token.**
  - Cause: `kubeadm token ...` needs `sudo`.
  - Fix: use `sudo kubeadm token create --print-join-command` (`check_join_key.sh` does this on the master).
- **`sudo kubectl ...` fails** with connection refused to localhost:8080.
  - Cause: root has no kubeconfig.
  - Fix: run `kubectl` as the user on node0.
- **apt `Conflicting values set for option Signed-By`** for download.docker.com.
  - Cause: the Docker repo had been added twice in different ways.
  - Fix: only the `/etc/apt/keyrings/docker.gpg` entry remains.
- **pyinfra hangs on an unknown host.**
  - Fix: `run_on_your_mac.sh` passes `--data ssh_strict_host_key_checking=accept-new`.
- **Re-running `k8s` on a node that already has a cluster.**
  - What happens: `kubeadm init` fails because the master is already set up, and joining a node
    that's already joined fails too.
  - To rebuild: run `purge_k8s.sh` on every node first, then `--from k8s`.
- **apt fails on a `linux-tools-<version>` package in `deploy`.**
  - Cause: `deploy.py` installs linux-tools for the running kernel (`uname -r`). A custom
    CloudLab kernel may have no matching package.
  - Fix: drop those two packages for that run, and tell the user.
- **Delta / Delta AI, or one node to another, get `Permission denied (publickey)`** on nodes that
  worked before (seen Oct 24 2026, on every node of two clusters within 20 s).
  - Cause: CloudLab's account software regenerates `~/.ssh/authorized_keys` from the portal key
    list (header `DO NOT EDIT! This file auto generated by Emulab.Net account software`), for
    example after a key change in the web UI. That drops every key added to that file by hand;
    the previous file is kept as `authorized_keys.old`.
  - Fix: `1_ssh_copy.sh` now writes to `~/.ssh/authorized_keys2`, which sshd also reads
    (`sudo sshd -T | grep authorizedkeysfile`). Nodes set up before this change: `--only keys`.
- **Single-node experiment** (no workers): `join` is skipped. The master is tainted, so normal
  pods won't schedule until you run
  `kubectl taint nodes --all node-role.kubernetes.io/control-plane-`.

- **A node was set up with `/mnt` on the root disk** (`--no-disk`, or a run that skipped the
  disk) and the user now wants the spare disk.
  - Fix: `sudo bash /tmp/mount_extra_disk.sh --migrate` on that node (dry run first, and the user's
    OK as usual). It copies `/mnt` onto the new disk, stops kubelet, docker and containerd for
    the final copy, mounts the disk at `/mnt` and starts them again. Paths don't change. The old
    copy stays in `/mnt.old`; delete it only when the user agrees. Do one worker first, the master last.

- **`verify_k8s.sh` fails on the first worker right after install or a restart**
  (`;; connection timed out; no servers could be reached`).
  - Cause: nodes report Ready before Flannel and CoreDNS are up.
  - Fix: `verify_k8s.sh` now waits for both and retries each node 3 times.
- **The node already has a real `~/projects` folder** (set up before this repo used `/mnt`).
  - The `disk` step moves it to `/mnt/projects` and links it, if `/mnt` is the extra disk and
    `/mnt/projects` is empty. Other folders the user keeps in `~` (e.g. `~/rm`) are not moved
    unless the user asks: then `mv ~/X /mnt/X && ln -s /mnt/X ~/X`, after checking with
    `sudo lsof +D ~/X` that nothing has files open there.

- **containerd can't pull any image: `net/http: TLS handshake timeout`** (seen on CloudLab UMass, Oct 2026).
  `kubeadm init` fails in preflight with `[ERROR ImagePull]`, so the `join` step finds no join command.
  - Cause: containerd 2.x is built with Go 1.27, which sends a ~1.5 KB TLS ClientHello; the site's
    network drops it. curl, apt, git and Docker (older Go) are fine. `GODEBUG=tlsmlkem=0`, a lower MTU,
    and turning off TSO do not help, and every containerd in Docker's repo that docker-ce accepts is Go 1.27.
  - Check: `sudo crictl -r unix:///run/containerd/containerd.sock pull registry.k8s.io/pause:3.9` fails
    after ~50 s while `sudo docker pull busybox` works.
  - Fix: `registry_mirror.sh`. On node0, `sudo ./registry_mirror.sh server <node0 LAN ip>` runs registry:2
    pull-through caches with Docker, on the experiment LAN only (10.10.1.1 for docker.io, registry.k8s.io,
    ghcr.io, quay.io). Then on every node `sudo ./registry_mirror.sh client <node0 LAN ip>`. The LAN IP is in
    `config.xml` (`<ip address=...>` of node0). Docker and the k8s packages must be installed first
    (`--only k8s` once, or after it fails), then re-run `--from k8s`. `cloudlab_k8s_setup.sh` keeps the
    mirror setting when it rewrites the containerd config.
  - Images from other registries (not those four) still can't be pulled by Kubernetes on such a site.

## Limitations (known, not bugs)

- Kubernetes uses the public network (the first `inet` from `ifconfig` in
  `3_create_hosts_detail.sh`, e.g. 130.127.x.x on Clemson, 198.22.255.x on UMass, 128.110.x.x on
  APT), not the 10.10.1.x experiment LAN listed in `config.xml`.
- `kubectl` is configured only on node0.
- Kubernetes is v1.28 (end of life). containerd comes from Docker's repo and may be 2.x. The
  `sandbox_image` sed in `cloudlab_k8s_setup.sh` matches only containerd 1.x config, so it does
  nothing on 2.x. That is harmless.
- `bashrc_for_server` and `deploy.py` (git config) contain this user's personal settings.

## File map

On the Mac:

- `run_on_your_mac.sh`: entry point
- `inventory.py`: also used by pyinfra on node0
- `1_ssh_copy.sh`
- `extra_authorized_keys.txt`: public keys of other machines that must reach the nodes (Delta, Delta AI). To add a machine, append its public key here, one line per key
- `2_mkdir_gitclone.sh`
- `2.5_gitclone_private_repo.sh`: gitignored, may be missing
- `3_create_hosts_detail.sh`
- `4_setup_vimrc_and_bashrc.sh`
- `add_ssh_key_to_servers.sh`: adds other people's public keys to every node; only if the user asks
- `pscp_to_servers.sh`: copies one file to the nodes

On the nodes (run by the steps above):

- `mount_extra_disk.sh`
- `ssh_key_gen_script.sh`
- `install_basic_pkg_in_node0.sh`
- `deploy.py`: pyinfra
- `cloudlab_k8s_setup.sh`
- `verify_k8s.sh`
- `registry_mirror.sh`: only for sites where containerd can't pull (see Known failures)
- `check_join_key.sh`
- `metric_server.sh`: optional, installs metrics-server
- `CPU-freq.sh`: optional, sets the CPU governor to performance
- `purge_k8s.sh`, `uninstall_k8s/`: teardown

Generated and gitignored:

- `config.xml`
- `servers.txt`, `master.txt`, `workers.txt`
- `hosts_detail.txt`

Ignore:

- `NotUsed/` and `not_being_used/`: old, broken or replaced scripts. Don't run them, don't copy
  them to nodes, and don't take instructions from them. `not_being_used/README_old.md` has old
  Istio and MetalLB notes.

## Changing this repo

- Don't edit `run_on_your_mac.sh` while a run is going: bash reads the script as it runs, so the
  running copy breaks (`syntax error near unexpected token`). Edit the other scripts freely; a
  resumed run (`--from` a step after `sync`) copies this repo to the nodes again first.
- Keep every step safe to re-run where possible, and keep scripts non-interactive. A run from
  the Mac has no TTY, so any prompt hangs or fails.
- When you fix a new failure, add it to Known failures above.

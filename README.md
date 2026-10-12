# cloudlab_script

Sets up CloudLab machines from a local Mac: ssh between nodes, an extra disk at `/mnt`,
repos, dotfiles, packages, and optionally a Kubernetes cluster.

**Agents and humans: read [AGENTS.md](AGENTS.md).** It has the procedure, the safety rules,
how to verify each step, and the known failures.

Quick version:

1. Paste the CloudLab manifest into `config.xml`.
2. `./run_on_your_mac.sh` (add `--k8s` for Kubernetes, `--help` for steps and options).

---
name: cloudlab-setup
description: Set up the CloudLab nodes in config.xml end to end (keys, extra disk, repos, packages, optional Kubernetes) and report the result.
argument-hint: "[k8s] [format|no-disk]"
disable-model-invocation: true
---

Set up the CloudLab cluster in `config.xml`. Follow AGENTS.md (procedure, safety rules, known
failures). This skill only removes the questions, so the user has as little to do as possible.

Arguments: `$ARGUMENTS`
- `k8s`: pass `--k8s`. Without it, no Kubernetes.
- `format`: the user approves formatting the disk the dry run selects on each node. Don't ask;
  still do the dry run and show it in the final report.
- `no-disk`: pass `--no-disk`, skip the dry run.
- Neither `format` nor `no-disk`: do the dry run and ask once. This is the only question you may ask.

Don't ask anything else:
- Private repos: if `GITHUB_ACCOUNT` and `CR_PAT` are set, clone them; otherwise skip and say so.
- Mac prerequisites: check them; if something is missing, stop and say exactly what to install.

Steps:
1. Check Mac prerequisites, then `python inventory.py` and show the node list in one line.
2. `./run_on_your_mac.sh --only keys`, then run its check from the Steps table.
3. Disk dry run (unless `no-disk`). With `format`, go on without asking. The decision is per
   node: `mount_extra_disk.sh` mounts the selected disk where there is one, and on a node with no
   usable disk it leaves `/mnt` on the root disk and carries on. So a node without a spare disk is
   not a reason to use `--no-disk`; use `--no-disk` only if the user asked for it.
   Never weaken the safety rules in AGENTS.md, even with `format`.
4. Run `./run_on_your_mac.sh --from disk [--k8s] [--no-disk] > /tmp/cloudlab_run.log 2>&1` in the
   background. Wait for it to finish; don't poll in a tight loop.
5. On `FAILED`: read the log, fix the cause (Known failures first), resume with `--from STEP`.
   Try at most twice per step, then stop and report.
6. Run the checks from the Steps table and the "Done means" list.

Final report, short:
- each node: hostname, disk mounted at `/mnt`, extra keys from `extra_authorized_keys.txt` present
- repos in `~/projects`
- deploy errors per host
- Kubernetes: `verify_k8s.sh` result (if `k8s`)
- anything skipped, fixed or changed in this repo (and add new failures to AGENTS.md Known failures)

#!/bin/bash
#
# Pull-through registry cache for networks where containerd can't pull images.
#
# Why: on CloudLab UMass (Oct 2026), containerd 2.x (built with Go 1.27) sends a large TLS
# ClientHello that the network drops, so every pull times out ("TLS handshake timeout").
# Docker (older Go) pulls fine. So node0 runs registry:2 proxy caches with Docker, and every
# node's containerd pulls through them over the experiment LAN.
#
# usage:
#   sudo ./registry_mirror.sh server <lan_ip>   # on node0: start the caches, listening on <lan_ip> only
#   sudo ./registry_mirror.sh client <lan_ip>   # on every node: point containerd at node0's caches

mode=$1
mirror_ip=$2
if [ -z "${mode}" ] || [ -z "${mirror_ip}" ]; then
    echo "usage: sudo $0 server|client <node0 LAN ip>"
    exit 1
fi
if [ "$(id -u)" -ne 0 ]; then
    echo "run with sudo"
    exit 1
fi

# registry name, upstream URL, local port
REGISTRIES="docker.io,https://registry-1.docker.io,5000
registry.k8s.io,https://registry.k8s.io,5001
ghcr.io,https://ghcr.io,5002
quay.io,https://quay.io,5003"

if [ "${mode}" == "server" ]; then
    status=0
    while IFS=, read -r name upstream port; do
        container=mirror-${name//./-}
        if ! docker ps --format '{{.Names}}' | grep -qx ${container}; then
            docker rm -f ${container} > /dev/null 2>&1
            docker run -d --restart=always --name ${container} \
                -p ${mirror_ip}:${port}:5000 \
                -e REGISTRY_PROXY_REMOTEURL=${upstream} \
                -v /mnt/registry-cache/${name}:/var/lib/registry \
                registry:2 > /dev/null || status=1
        fi
        echo "${name} -> http://${mirror_ip}:${port} (${container})"
    done <<< "${REGISTRIES}"
    exit ${status}
fi

if [ "${mode}" == "client" ]; then
    while IFS=, read -r name upstream port; do
        mkdir -p /etc/containerd/certs.d/${name}
        cat > /etc/containerd/certs.d/${name}/hosts.toml <<EOF
server = "${upstream}"

[host."http://${mirror_ip}:${port}"]
  capabilities = ["pull", "resolve"]
EOF
    done <<< "${REGISTRIES}"
    # Both the CRI plugin (kubelet) and the transfer service (ctr) read hosts.toml from here
    sed -i "s|config_path = ''|config_path = '/etc/containerd/certs.d'|" /etc/containerd/config.toml
    systemctl restart containerd
    echo "containerd on $(hostname -s) pulls through ${mirror_ip}"
    exit 0
fi

echo "unknown mode: ${mode}"
exit 1

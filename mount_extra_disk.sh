#!/bin/bash
#
# Format and mount one unused whole disk at /mnt, so docker, containerd, repos and the venv
# don't fill the small root filesystem. Disk names differ per CloudLab hardware type
# (sdb, nvme0n1, ...), so the disk is detected, not hardcoded.
#
# Safety: never touches the disk that holds /, and only uses a disk that has no partitions,
# no filesystem/LVM signature and nothing mounted. If no such disk exists, it does nothing.
#
# If /mnt already has files (a node set up with --no-disk), it refuses to mount over them unless
# --migrate is given: then it copies /mnt onto the new disk, stopping kubelet, docker and containerd
# for the final copy, mounts the disk at /mnt, starts them again, and keeps the old copy in /mnt.old.
#
# usage: sudo ./mount_extra_disk.sh [--dry-run] [--migrate]

MOUNT_POINT=/mnt
MIN_SIZE_GB=50
OWNER=${SUDO_USER:-$USER}

dry_run=false
migrate=false
for arg in "$@"; do
    case ${arg} in
        --dry-run) dry_run=true ;;
        --migrate) migrate=true ;;
        *) echo "unknown argument: ${arg}"; exit 1 ;;
    esac
done

if [ "${dry_run}" == false ] && [ "$(id -u)" -ne 0 ]; then
    echo "run with sudo"
    exit 1
fi

if mountpoint -q ${MOUNT_POINT}; then
    echo "${MOUNT_POINT} is already a mount point ($(findmnt -no SOURCE ${MOUNT_POINT})). Nothing to do."
    exit 0
fi

# Disk that holds / (walk up from the root partition / LVM volume to the physical disk)
root_source=$(findmnt -no SOURCE /)
root_disks=$(lsblk -nrso NAME,TYPE "${root_source}" | awk '$2 == "disk" {print $1}')
echo "root filesystem: ${root_source} on disk(s): ${root_disks}"

candidates=()
while read -r name type size rota ro rm; do
    [ "${type}" == "disk" ] || continue
    [[ "${name}" == zram* ]] && continue
    echo " ${root_disks} " | grep -q " ${name} " && continue
    [ "${ro}" == "1" ] || [ "${rm}" == "1" ] && continue
    [ "${size}" -ge $((MIN_SIZE_GB * 1024 * 1024 * 1024)) ] || continue
    # no partitions or other children, nothing mounted, no filesystem/LVM/RAID signature
    [ "$(lsblk -nr /dev/${name} | wc -l)" -eq 1 ] || continue
    [ -z "$(lsblk -dno MOUNTPOINT /dev/${name})" ] || continue
    [ -z "$(blkid -p /dev/${name} 2>/dev/null)" ] || continue
    candidates+=("${rota} ${size} ${name}")
    echo "candidate: /dev/${name} $((size / 1024 / 1024 / 1024))G rotational=${rota}"
done < <(lsblk -dnbo NAME,TYPE,SIZE,ROTA,RO,RM)

if [ ${#candidates[@]} -eq 0 ]; then
    echo "WARNING: no unused disk found. ${MOUNT_POINT} stays on the root filesystem."
    disk=""
else
    # SSD/NVMe first, then the largest
    disk=$(printf '%s\n' "${candidates[@]}" | sort -k1,1n -k2,2nr | head -n 1 | awk '{print $3}')
    echo "selected: /dev/${disk}"
fi

if [ "${dry_run}" == true ]; then
    echo "(dry run, nothing changed)"
    exit 0
fi

if [ -n "${disk}" ]; then
    # Mounting over a non-empty /mnt would hide its files (e.g. a node set up with --no-disk)
    if [ -n "$(ls -A ${MOUNT_POINT} 2>/dev/null)" ] && [ "${migrate}" != true ]; then
        echo "WARNING: ${MOUNT_POINT} is not empty, not mounting over it. ${MOUNT_POINT} stays on the root filesystem."
        echo "Use --migrate to move its contents onto /dev/${disk}:"
        ls -A ${MOUNT_POINT}
        disk=""
    fi
fi

start_services () {
    for s in containerd docker kubelet; do
        echo " ${stopped} " | grep -q " ${s} " && systemctl start ${s}
    done
}

if [ -n "${disk}" ] && [ -n "$(ls -A ${MOUNT_POINT} 2>/dev/null)" ]; then
    if [ -e ${MOUNT_POINT}.old ]; then
        echo "ERROR: ${MOUNT_POINT}.old already exists. Remove it first."
        exit 1
    fi
    staging=${MOUNT_POINT}.new
    mkfs.ext4 -F -q /dev/${disk} || exit 1
    mkdir -p ${staging}
    mount /dev/${disk} ${staging} || exit 1
    echo "copying ${MOUNT_POINT} to /dev/${disk} (first pass, services still running)"
    rsync -aHAXS ${MOUNT_POINT}/ ${staging}/ || exit 1

    # Stop everything that writes to /mnt. kubelet recreates the pods when it starts again.
    stopped=""
    for s in kubelet docker containerd; do
        systemctl is-active -q ${s} && stopped="${stopped} ${s}"
    done
    echo "stopping:${stopped}"
    if echo " ${stopped} " | grep -q " kubelet "; then
        systemctl stop kubelet
        crictl -r unix:///run/containerd/containerd.sock stopp $(crictl -r unix:///run/containerd/containerd.sock pods -q) > /dev/null 2>&1
        crictl -r unix:///run/containerd/containerd.sock rmp -a -f > /dev/null 2>&1
    fi
    if echo " ${stopped} " | grep -q " docker "; then
        docker ps -q | xargs -r docker stop > /dev/null
        systemctl stop docker docker.socket
    fi
    echo " ${stopped} " | grep -q " containerd " && systemctl stop containerd
    if findmnt -rn -o TARGET | grep -q "^${MOUNT_POINT}/"; then
        echo "ERROR: something is still mounted under ${MOUNT_POINT}, not moving it:"
        findmnt -rn -o TARGET | grep "^${MOUNT_POINT}/"
        umount ${staging}; start_services; exit 1
    fi

    echo "copying ${MOUNT_POINT} to /dev/${disk} (final pass)"
    if ! rsync -aHAXS --delete ${MOUNT_POINT}/ ${staging}/; then
        umount ${staging}; start_services; exit 1
    fi
    umount ${staging} && rmdir ${staging}
    mv ${MOUNT_POINT} ${MOUNT_POINT}.old && mkdir ${MOUNT_POINT}
    echo "old ${MOUNT_POINT} kept in ${MOUNT_POINT}.old. Delete it after checking: sudo rm -rf ${MOUNT_POINT}.old"
    formatted=true
fi

if [ -n "${disk}" ]; then
    [ "${formatted}" == true ] || mkfs.ext4 -F -q /dev/${disk} || exit 1
    uuid=$(blkid -s UUID -o value /dev/${disk})
    mkdir -p ${MOUNT_POINT}
    grep -q "UUID=${uuid}" /etc/fstab || echo "UUID=${uuid} ${MOUNT_POINT} ext4 defaults,nofail 0 2" >> /etc/fstab
    if ! mount ${MOUNT_POINT}; then
        if [ "${formatted}" == true ]; then
            echo "ERROR: mount failed, putting the old ${MOUNT_POINT} back"
            rmdir ${MOUNT_POINT} && mv ${MOUNT_POINT}.old ${MOUNT_POINT}
            sed -i "\|^UUID=${uuid} |d" /etc/fstab
            start_services
        fi
        exit 1
    fi
    echo "mounted /dev/${disk} at ${MOUNT_POINT}"
    start_services
fi

mkdir -p ${MOUNT_POINT}/projects
chown ${OWNER} ${MOUNT_POINT} ${MOUNT_POINT}/projects
df -h ${MOUNT_POINT}

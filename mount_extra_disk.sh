#!/bin/bash
#
# Format and mount one unused whole disk at /mnt, so docker, containerd, repos and the venv
# don't fill the small root filesystem. Disk names differ per CloudLab hardware type
# (sdb, nvme0n1, ...), so the disk is detected, not hardcoded.
#
# Safety: never touches the disk that holds /, and only uses a disk that has no partitions,
# no filesystem/LVM signature and nothing mounted. If no such disk exists, it does nothing.
#
# usage: sudo ./mount_extra_disk.sh [--dry-run]

MOUNT_POINT=/mnt
MIN_SIZE_GB=50
OWNER=${SUDO_USER:-$USER}

dry_run=false
[ "$1" == "--dry-run" ] && dry_run=true

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
    # Mounting over a non-empty /mnt would hide its files (e.g. a node set up before this script existed)
    if [ -n "$(ls -A ${MOUNT_POINT} 2>/dev/null)" ]; then
        echo "WARNING: ${MOUNT_POINT} is not empty, not mounting over it. ${MOUNT_POINT} stays on the root filesystem:"
        ls -A ${MOUNT_POINT}
        disk=""
    fi
fi

if [ -n "${disk}" ]; then
    mkfs.ext4 -F -q /dev/${disk} || exit 1
    uuid=$(blkid -s UUID -o value /dev/${disk})
    mkdir -p ${MOUNT_POINT}
    grep -q "UUID=${uuid}" /etc/fstab || echo "UUID=${uuid} ${MOUNT_POINT} ext4 defaults,nofail 0 2" >> /etc/fstab
    mount ${MOUNT_POINT} || exit 1
    echo "mounted /dev/${disk} at ${MOUNT_POINT}"
fi

mkdir -p ${MOUNT_POINT}/projects
chown ${OWNER} ${MOUNT_POINT} ${MOUNT_POINT}/projects
df -h ${MOUNT_POINT}

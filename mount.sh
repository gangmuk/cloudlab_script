set -x

sudo apt-get install xfsprogs -y

DEVICE_NAME=/dev/nvme0n1
MOUNT_POINT=/cache_check

sudo mkfs.xfs -f ${DEVICE_NAME}
sudo mkdir -p ${MOUNT_POINT}
sudo mount ${DEVICE_NAME} ${MOUNT_POINT}
#sudo mount ${MOUNT_POINT} ${DEVICE_NAME}
sudo chown $USER ${MOUNT_POINT}
sudo ln -s ${MOUNT_POINT} ~/cache_check

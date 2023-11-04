set -x

sudo apt-get install xfsprogs -y

DEVICE_NAME=/dev/nvme1n1
MOUNT_POINT=/mount

#sudo mkfs.xfs -f ${DEVICE_NAME}
sudo mkfs.ext4 ${DEVICE_NAME} &&
sudo mkdir -p ${MOUNT_POINT} &&
sudo mount ${DEVICE_NAME} ${MOUNT_POINT} &&
sudo chown $USER ${MOUNT_POINT} &&

#simlink_path=${simlink_path}
#mkdir ${simlink_path} &&
sudo ln -s ${MOUNT_POINT} ${HOME}/${MOUNT_POINT}

# src_file=$1
# if [ -z $src_file ]; then
#     echo "Usage: $0 <file>"
#     exit 1
# fi

src_file=$1
if [ -z $src_file ]; then
    echo "Usage: $0 <file>"
    exit 1
fi
dst="/users/gangmuk/projects/cloudlab_script/${src_file}"
echo "Copying ${src_file} to ${dst}"
echo "Start in 3 seconds..."
sleep 3

pscp -h servers.txt ${src_file} ${dst}

# src_file=$1
# if [ -z $src_file ]; then
#     echo "Usage: $0 <file>"
#     exit 1
# fi

src_file="purge_k8s.sh"

echo "Copying [[[${src_file}]]] to servers..."
echo "Start in 5 seconds..."
sleep 5

pscp -h servers.txt ${src_file} /users/gangmuk/projects/cloudlab_script

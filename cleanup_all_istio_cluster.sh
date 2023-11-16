read -p "Are you sure that you want to delete istio in cluster 1? [Y/N]" inp
if [ $inp == "Y"]
then
    istioctl uninstall --context="${CTX_CLUSTER1}" -y --purge
    kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
fi

read -p "Are you sure that you want to delete istio in cluster 2? [Y/N]" inp
if [ $inp == "Y"]
then
    istioctl uninstall --context="${CTX_CLUSTER2}" -y --purge
    kubectl delete ns istio-system --context="${CTX_CLUSTER2}"
fi

# This is currently for one cluster

read -p "What's the CLUSTER_ID? [1 or 2]: " CLUSTER_ID
if [ $CLUSTER_ID == '1' ] && [$CLUSTER_ID == '2' ]
then
    echo "Invalid CLUSTER_ID: $CLUSTER_ID"
    exit
fi
echo CLUSTER_ID: $CLUSTER_ID

# Install istioctl
cd ~
curl -sL https://istio.io/downloadIstioctl | sh -
export PATH=$HOME/.istioctl/bin:$PATH

### Install istio
git clone https://github.com/istio/istio.git;
cd istio;
kubectl create namespace istio-system;

cat <<EOF > cluster1.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster1
      network: network1
EOF

cat <<EOF > cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster2
      network: network2
EOF

if [ $CLUSTER_ID == '1' ]
then
    # cluster 1
    kubectl --context="${CTX_CLUSTER1}" get namespace istio-system && kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=network1;
    kubectl label namespace default istio-injection=enabled;
    istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml;

    # eastwest gateway
    samples/multicluster/gen-eastwest-gateway.sh --mesh mesh1 --cluster cluster1 --network network1 | istioctl --context="${CTX_CLUSTER1}" install -y -f -
elif [ $CLUSTER_ID == '2' ]
then
    # cluster 2
    kubectl --context="${CTX_CLUSTER2}" get namespace istio-system && kubectl --context="${CTX_CLUSTER2}" label namespace istio-system topology.istio.io/network=network2
    kubectl label namespace default istio-injection=enabled;
    istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml

    # eastwest gateway
    samples/multicluster/gen-eastwest-gateway.sh --mesh mesh1 --cluster cluster2 --network network2 | istioctl --context="${CTX_CLUSTER2}" install -y -f -
else
    echo "WRONG CLUSTER_ID: $CLUSTER_ID"
    exit
fi

# bookinfo
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml;
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

# Expose service
if [ $CLUSTER_ID == '1' ]
then
    kubectl --context="${CTX_CLUSTER1}" apply -n istio-system -f samples/multicluster/expose-services.yaml
elif [ $CLUSTER_ID == '2' ]
then
    kubectl --context="${CTX_CLUSTER2}" apply -n istio-system -f samples/multicluster/expose-services.yaml
else
    echo "WRONG CLUSTER_ID: $CLUSTER_ID"
fi

echo "Enable endpoint discovery"
if [ $CLUSTER_ID == '1' ]
then
    istioctl create-remote-secret \
      --context="${CTX_CLUSTER1}" \
      --name=cluster2 | \
      kubectl apply -f - --context="${CTX_CLUSTER2}"
elif  [ $CLUSTER_ID == '2' ]
then
    istioctl create-remote-secret \
      --context="${CTX_CLUSTER2}" \
      --name=cluster1 | \
      kubectl apply -f - --context="${CTX_CLUSTER1}"
else
    echo "WRONG CLUSTER_ID: $CLUSTER_ID"
fi

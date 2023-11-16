# This is currently for one cluster

### Install istio
git clone https://github.com/istio/istio.git;
cd istio;
kubectl create namespace istio-system;


# cluster 1
kubectl --context="${CTX_CLUSTER1}" get namespace istio-system && kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=network1;
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
kubectl label namespace default istio-injection=enabled;
istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml;

# eastwest gateway
samples/multicluster/gen-eastwest-gateway.sh --mesh mesh1 --cluster cluster1 --network network1 | istioctl --context="${CTX_CLUSTER1}" install -y -f -

# bookinfo
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml;
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

# Expose service in cluster 1
kubectl --context="${CTX_CLUSTER1}" apply -n istio-system -f samples/multicluster/expose-services.yaml

############
# cluster 2
############
# Cluster 2 should be run in cluster 2 not in cluster 1
#kubectl --context="${CTX_CLUSTER2}" get namespace istio-system && kubectl --context="${CTX_CLUSTER2}" label namespace istio-system topology.istio.io/network=network2
#cat <<EOF > cluster2.yaml
#apiVersion: install.istio.io/v1alpha1
#kind: IstioOperator
#spec:
#  values:
#    global:
#      meshID: mesh1
#      multiCluster:
#        clusterName: cluster2
#      network: network2
#EOF
#istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
#
## eastwest gateway
#samples/multicluster/gen-eastwest-gateway.sh \
#    --mesh mesh1 --cluster cluster2 --network network2 | \
#    istioctl --context="${CTX_CLUSTER2}" install -y -f -
## bookinfo
#kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml;
#kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
## service expose
#kubectl --context="${CTX_CLUSTER2}" apply -n istio-system -f \
#    samples/multicluster/expose-services.yaml


#################################################################
# Enable Endpoint Discovery
## cluster 1 can access cluster 2
#istioctl create-remote-secret \
#  --context="${CTX_CLUSTER1}" \
#  --name=cluster1 | \
#  kubectl apply -f - --context="${CTX_CLUSTER2}"
### cluster 2 can access cluster 1
#istioctl create-remote-secret \
#  --context="${CTX_CLUSTER2}" \
#  --name=cluster2 | \
#  kubectl apply -f - --context="${CTX_CLUSTER1}"
#
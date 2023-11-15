### ISTIO STEPS
git clone https://github.com/istio/istio.git;
cd istio;
kubectl create namespace istio-system;
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
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml;
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

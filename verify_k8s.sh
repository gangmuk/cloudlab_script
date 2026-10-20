#!/bin/bash
#
# Run on the master node. Passes when every node is Ready and a pod on every worker
# can resolve a cluster DNS name (CoreDNS runs on the master, so this crosses the pod network).
#
# usage: ./verify_k8s.sh

echo "Waiting up to 5 minutes for all nodes to be Ready..."
if ! kubectl wait --for=condition=Ready node --all --timeout=300s; then
    kubectl get nodes -o wide
    echo "FAIL: not all nodes are Ready"
    exit 1
fi
kubectl get nodes -o wide

# Nodes turn Ready before the pod network and DNS are up, so wait for those too
kubectl -n kube-flannel rollout status daemonset/kube-flannel-ds --timeout=300s
kubectl -n kube-system rollout status deployment/coredns --timeout=300s

status=0
workers=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].metadata.name}')
for node in ${workers}; do
    pod=nettest-$(echo ${node} | cut -d. -f1)
    ok=false
    # A few tries: right after setup, the first lookups can still time out
    for attempt in 1 2 3; do
        kubectl delete pod ${pod} --ignore-not-found --wait=true > /dev/null
        kubectl run ${pod} --image=busybox:1.36 --restart=Never \
            --overrides="{\"spec\":{\"nodeName\":\"${node}\"}}" \
            -- nslookup kubernetes.default.svc.cluster.local > /dev/null
        if kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/${pod} --timeout=60s > /dev/null; then
            ok=true; break
        fi
        echo "retrying ${node} (attempt ${attempt} failed)"
        sleep 10
    done
    if [ ${ok} == true ]; then
        echo "OK:   pod network + DNS from ${node}"
    else
        echo "FAIL: pod network + DNS from ${node}"
        kubectl logs ${pod} 2>&1 | tail -5
        status=1
    fi
    kubectl delete pod ${pod} --wait=false > /dev/null
done

if [ ${status} -eq 0 ]; then
    echo "PASS: kubernetes cluster is healthy"
else
    echo "FAIL: see above"
fi
exit ${status}

#!/usr/bin/env bash

set -euxo pipefail

if [ "$#" -gt 2 ]; then
  echo "Usage: $0 [number_of_nodes: 2] [use_cilium: false]"
  exit 1
fi

NUM_NODES=${1:-2}
USE_CILIUM=${2:-false}

CNI="auto"
EXTRA_CONFIG=""
if [ "$USE_CILIUM" = true ]; then
  CNI="bridge" # manually install Cilium to use instead of kube-proxy and enable Hubble
  EXTRA_CONFIG="--extra-config=kubeadm.skip-phases=addon/kube-proxy"
fi

minikube start \
  --nodes="$NUM_NODES" \
  --cpus=no-limit \
  --memory=no-limit \
  --cni="$CNI" \
  --insecure-registry="host.minikube.internal:5000" \
  $EXTRA_CONFIG

WORKER_NODES=$(kubectl get nodes --no-headers | grep -E '\-m' | awk '{print $1}')
for NODE in $WORKER_NODES; do
  kubectl label node "$NODE" node-role.kubernetes.io/worker=worker
done

if [ "$NUM_NODES" -gt 2 ]; then
  kubectl taint nodes minikube node-role.kubernetes.io/control-plane=:NoSchedule
fi

if [ "$USE_CILIUM" = true ]; then
  helmfile apply --skip-diff-on-install --suppress-diff -f helm/helmfile.yaml -l name=cilium \
    --set k8sServiceHost="$(minikube ip)" --set k8sServicePort=8443

  # without kube-proxy, we need to update CoreDNS to use the host's DNS server
  # see: https://github.com/cilium/cilium/issues/29113
  kubectl get cm coredns -n kube-system -o yaml >coredns.yaml
  dns_server=$(scutil --dns | grep 'nameserver' | awk 'NR==1 {print $3}')
  sed -i'.bak' "s/forward \. \/etc\/resolv\.conf/forward \. $dns_server/" coredns.yaml
  kubectl apply -f coredns.yaml
  rm -rf coredns.yaml coredns.yaml.bak
  kubectl -n kube-system rollout restart deploy coredns

  # restart pods that are not using hostNetwork to pick up the Cilium CNI
  pods_to_restart=$(kubectl get pods -A --no-headers=true \
    -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork |
    grep '<none>')
  echo -n "$pods_to_restart" | awk '{print "-n "$1" "$2}' | xargs -L 1 -r kubectl delete pod
fi

helmfile apply --skip-diff-on-install --suppress-diff -f helm/helmfile.yaml -l name!=cilium

cm=chartmuseum
kubectl expose deploy $cm -n $cm --name $cm-node --type=NodePort \
  --overrides '{"spec": {"ports": [{"port": 8080, "nodePort": 30080}]}}'

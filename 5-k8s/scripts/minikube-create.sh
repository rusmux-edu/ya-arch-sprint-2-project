#!/usr/bin/env bash

set -euxo pipefail

if [ "$#" -gt 2 ]; then
  echo "Usage: $0 [number_of_nodes: 2] [use_cilium: false]"
  exit 1
fi

NUM_NODES=${1:-2}
USE_CILIUM=${2:-false}

HOST_IP=$(ip -4 addr | grep inet | awk 'NR==2 {print $2}' | cut -d '/' -f1)

CNI="auto"
if [ "$USE_CILIUM" = true ]; then
  CNI="bridge" # manually install Cilium to enable Hubble
fi

minikube start \
  --nodes="$NUM_NODES" \
  --cpus=no-limit \
  --memory=no-limit \
  --cni="$CNI" \
  --insecure-registry="$HOST_IP:5000"

WORKER_NODES=$(kubectl get nodes --no-headers | grep -E '\-m' | awk '{print $1}')
for NODE in $WORKER_NODES; do
  kubectl label node "$NODE" node-role.kubernetes.io/worker=worker
done

if [ "$NUM_NODES" -gt 2 ]; then
  kubectl taint nodes minikube node-role.kubernetes.io/control-plane=:NoSchedule
fi

if [ "$USE_CILIUM" = true ]; then
  helmfile apply --skip-diff-on-install --suppress-diff -f helm/helmfile.yaml -l name=cilium

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

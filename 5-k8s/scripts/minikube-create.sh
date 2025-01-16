#!/usr/bin/env bash

set -euxo pipefail

HOST_IP=$(ip -4 addr | grep inet | awk 'NR==2 {print $2}' | cut -d '/' -f1)

minikube start \
  --nodes=3 \
  --cpus='no-limit' \
  --memory='no-limit' \
  --insecure-registry="$HOST_IP:5000"

WORKER_NODES=$(kubectl get nodes --no-headers | grep -E '\-m' | awk '{print $1}')
for NODE in $WORKER_NODES; do
  kubectl label node "$NODE" node-role.kubernetes.io/worker=worker
done

kubectl taint nodes minikube node-role.kubernetes.io/control-plane=:NoSchedule

kd="kubernetes-dashboard"
helm install $kd $kd/$kd -n $kd --create-namespace

helm install metrics-server metrics-server/metrics-server -n kube-system \
  --set 'args[0]="--kubelet-insecure-tls"' \
  --set existingArgsAppend=true

es="external-secrets"
helm install $es $es/$es -n $es --create-namespace

cm="chartmuseum"
helm install $cm $cm/$cm -n $cm --create-namespace --set env.open.DISABLE_API=false
kubectl expose deploy $cm -n $cm --name $cm-node --type=NodePort \
  --overrides '{"spec": {"ports": [{"port": 8080, "nodePort": 30080}]}}'

kubectl apply -f https://github.com/knative/operator/releases/latest/download/operator.yaml

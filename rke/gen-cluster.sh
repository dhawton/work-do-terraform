#!/bin/bash

if [[ "$2" == "" ]]; then
  echo "Missing params"
  exit 1
fi

my_hostname=$1
domain=$2
ipv4=$(dig +short $my_hostname.$2)
internal_ipv4=$(dig +short ${my_hostname}.i.$domain)

ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$my_hostname.$domain" &>/dev/null
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$ipv4" &>/dev/null

if [[ -f "cluster.rkestate" ]]; then
  echo "rkestate exists, this might be bad?"
  rm cluster.rkestate
fi
if [[ -f "kube_config_cluster.yml" ]]; then
  echo "kube config exists, this might be bad?"
  rm kube_config_cluster.yml
fi

cat >cluster.yml <<!TEMPLATE!
nodes:
- address: $ipv4
  port: "22"
  internal_address: $internal_ipv4
  role:
  - controlplane
  - worker
  - etcd
  hostname_override: $my_hostname.$domain
  user: daniel
  docker_socket: /var/run/docker.sock
  ssh_key_path: ~/.ssh/id_ecdsa
!TEMPLATE!

echo "Saved to cluster.yml"

function kc() {
  kubectl --kubeconfig=kube_config_cluster.yml $@
}

function hlm() {
  KUBECONFIG=./kube_config_cluster.yml helm $@
}

function log() {
  echo ""
  echo "$@"
}

log "rke up'ing"
rke up

if [[ ! -f "kube_config_cluster.yml" ]]; then
  echo "kube_config_cluster.yml is missing, possible rke failure?"
  exit 1
fi

chmod 600 kube_config_cluster.yml

log "Adding rancher chart, likely to already exist..."
hlm repo add rancher-latest https://releases.rancher.com/server-charts/latest

log "Updating helm repo"
hlm repo update

log "Adding jetstack helm repo and updating repos"
hlm repo add jetstack https://charts.jetstack.io
hlm repo update

log "Installing cert-manager..."
hlm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.4.0 \
  --set installCRDs=true

log "Waiting for deployment..."
kc -n cert-manager rollout status deploy/cert-manager

log "Creating cattle-system namespace"
kc create namespace cattle-system

log "Installing Rancher from charts"
hlm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=$my_hostname.$domain \
  --set replicas=1 \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=daniel.hawton@suse.com

log "Waiting for Rancher deployment"
kc -n cattle-system rollout status deploy/rancher

log "Done."
echo "You can access the install at https://$my_hostname.$domain"

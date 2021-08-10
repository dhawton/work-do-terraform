#!/bin/bash

. ../buildconfig.sh

if [[ "$3" == "" ]]; then
  echo "Missing params"
  exit 1
fi

ipv4=$(cat ../terraform.tfstate | jq -r '.outputs.rancher_ip.value')

ssh-keygen -f "$HOME/.ssh/known_hosts" -R "${instance_name}.${domain_name}" &>/dev/null
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$ipv4" &>/dev/null

if [[ -f "cluster.rkestate" ]]; then
  echo "rkestate exists, this might be bad?"
  rm cluster.rkestate
fi
if [[ -f "kube_config_cluster.yml" ]]; then
  echo "kube config exists, this might be bad?"
  rm kube_config_cluster.yml
fi

kubernetes_version=""
if [[ ${k8s_version} != "latest" ]]; then
  kubernetes_version=$k8s_version
fi

cat >cluster.yml <<!TEMPLATE!
nodes:
- address: $ipv4
  port: "22"
  role:
  - controlplane
  - worker
  - etcd
  hostname_override: ${instance_name}.${domain_name}
  user: $ssh_username
  docker_socket: /var/run/docker.sock
  ssh_key_path: $ssh_key
kubernetes_version: $kubernetes_version
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

if [[ $install_rancher == "n" ]]; then
  echo "Not configured to install rancher, we're done here."
  exit 0
fi

log "Adding rancher chart, likely to already exist..."
hlm repo add rancher-latest https://releases.rancher.com/server-charts/latest

# log "Updating helm repo"
# hlm repo update

# log "Adding jetstack helm repo and updating repos"
# hlm repo add jetstack https://charts.jetstack.io
# hlm repo update

# log "Installing cert-manager..."
# kc create namespace cert-manager
# kc apply -f https://github.com/jetstack/cert-manager/releases/download/v1.4.0/cert-manager.yaml
# hlm install cert-manager jetstack/cert-manager \
#   --namespace cert-manager \
#   --version v1.4.0

# log "Waiting for deployment..."
# kc -n cert-manager rollout status deploy/cert-manager
# kc -n cert-manager rollout status deploy/cert-manager-webhook
# kc -n cert-manager rollout status deploy/cert-manager-cainjector

# log "Giving cert-manager more time to finish deploying"
# sleep 30

log "Creating secret"
kc -n cattle-system create secret tls tls-rancher-ingress --cert=$rancher_cert --key=$rancher_key

if [[ ! -z "$rancher_ca" ]]; then
  log "Creating CA secret"
  kc -n cattle-system create secret generic tls-ca --from-file=cacerts.pem=${rancher_ca}
fi

log "Creating cattle-system namespace"
kc create namespace cattle-system

rancher_arg=""
if [[ $rancher_version != "latest" ]]; then
  rancher_arg="--version ${rancer_version}"
fi

if [[ $rancher_ca != "" ]]; then
  rancher_arg="--set privateCA=true ${rancher_arg}"
fi

log "Installing Rancher from charts"
hlm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=${instance_name}.${domain_name} \
  --set replicas=1 \
  --set ingress.tls.source=secret \
  $ranger_arg

log "Waiting for Rancher deployment"
kc -n cattle-system rollout status deploy/rancher

log "Done."
echo "You can access the install at https://${instance_name}.${domain_name}"

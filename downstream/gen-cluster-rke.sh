#!/bin/bash

. ../buildconfig.sh

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

node1_name=$(cat terraform.tfstate | jq -r '.outputs.node1_name.value')
node1_ip=$(cat terraform.tfstate | jq -r '.outputs.node1_ip.value')
node1_internal_ip=$(cat terraform.tfstate | jq -r '.outputs.node1_internal_ip.value')
node2_name=$(cat terraform.tfstate | jq -r '.outputs.node2_name.value')
node2_ip=$(cat terraform.tfstate | jq -r '.outputs.node2_ip.value')
node2_internal_ip=$(cat terraform.tfstate | jq -r '.outputs.node2_internal_ip.value')
node3_name=$(cat terraform.tfstate | jq -r '.outputs.node3_name.value')
node3_ip=$(cat terraform.tfstate | jq -r '.outputs.node3_ip.value')
node3_internal_ip=$(cat terraform.tfstate | jq -r '.outputs.node3_internal_ip.value')

cat >cluster.yml <<!TEMPLATE!
nodes:
- address: $node1_ip
  port: "22"
  role:
  - controlplane
  - worker
  - etcd
  internal_address: $node1_internal_ip
  hostname_override: ${node1_name}
  user: $ssh_username
  docker_socket: /var/run/docker.sock
  ssh_key_path: $ssh_key
- address: $node2_ip
  port: "22"
  role:
  - controlplane
  - worker
  - etcd
  internal_address: $node2_internal_ip
  hostname_override: ${node2_name}
  user: $ssh_username
  docker_socket: /var/run/docker.sock
  ssh_key_path: $ssh_key
- address: $node3_ip
  port: "22"
  role:
  - controlplane
  - worker
  - etcd
  internal_address: $node3_internal_ip
  hostname_override: ${node3_name}
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
echo "Downstream cluster is available"
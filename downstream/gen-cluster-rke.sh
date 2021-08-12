#!/bin/bash

. ../buildconfig.sh
. gen-cluster-common.sh

kubernetes_version=""
if [[ ${downstream_kubernetes_version} != "latest" ]]; then
  kubernetes_version=$downstream_kubernetes_version
fi

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
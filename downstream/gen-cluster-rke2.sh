#!/bin/bash

. ../buildconfig.sh
. gen-cluster-common.sh

rke2_token=$(date +%s | sha256sum | base64 | head -c 16 ; echo)
lb_hostname=$(cat terraform.tfstate | jq -r '.outputs.lb_name.value')

function do_install() {
    local first_node=$1
    local ip=$2
    local cmdargs=""
    echo ""
    echo "Installing on $3"
    hostname=$(echo $3 | tr -d " ")
    echo "Setting hostname to $hostname"
    ssh -o "StrictHostKeyChecking=no" -l $ssh_username $ip "sudo hostnamectl set-hostname $hostname"
    if [[ $first_node == "true" ]]; then
      echo "Creating config.yaml"
      ssh -o "StrictHostKeyChecking=no" -l $ssh_username $ip "sudo mkdir -p /etc/rancher/rke2 && \
        sudo sh -c 'printf \"token: $rke2_token\ntls-san:\n  - ${lb_hostname}\" > /etc/rancher/rke2/config.yaml'"
    else
      echo "Creating config.yaml"
      ssh -o "StrictHostKeyChecking=no" -l $ssh_username $ip "sudo mkdir -p /etc/rancher/rke2 && \
        sudo sh -c 'echo \"server: https://${lb_hostname}:9345\" > /etc/rancher/rke2/config.yaml' && \
        sudo sh -c 'printf \"token: $rke2_token\ntls-san:\n  - ${lb_hostname}\" > /etc/rancher/rke2/config.yaml'"
    fi
    echo "Installing RKE2..."
    ssh -o "StrictHostKeyChecking=no" -l $ssh_username $ip "curl -sfL https://get.rke2.io -o /tmp/install.sh; sudo INSTALL_RKE2_CHANNEL=${downstream_kubernetes_version} sh /tmp/install.sh"
    echo "Enabling and starting service..."
    ssh -o "StrictHostKeyChecking=no" -l $ssh_username $ip "sudo systemctl enable rke2-server.service && sudo systemctl start rke2-server.service"
    echo "Giving time to spin up..."
    sleep 15
    echo "Done"
}

function wait_kubeapi_ready() {
  curl -ks https://${node1_ip}:6443/version
  if [[ $? -eq 0 ]]; then
    echo "Kubernetes API is ready, continuing"
    return
  fi
  sleep 10
  wait_kubeapi_ready
}

do_install true $node1_ip "Node 1"
sleep 5
echo "Waiting for first server's kubeapi to be ready"
wait_kubeapi_ready
do_install false $node2_ip "Node 2"
sleep 5
do_install false $node3_ip "Node 3"
sleep 5
echo "Giving extra spin up time..."
sleep 10
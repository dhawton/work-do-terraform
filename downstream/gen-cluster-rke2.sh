#!/bin/bash

. ../buildconfig.sh
. gen-cluster-common.sh

rke2_token=$(date +%s | sha256sum | base64 | head -c 16 ; echo)

function do_install() {
    local first_node=$1
    local ip=$2
    local cmdargs=""
    echo ""
    echo "Installing on $3"
    if [[ $first_node ]]; then
      echo "Creating config.yaml"
      ssh -o "StrictHostKeyChecking=no" -l $ssh_username $ip "sudo mkdir -p /etc/rancher/rke2 && \
        sudo echo \"token: $rke2_token\" > /etc/rancher/rke2/config.yaml"
    else
      echo "Creating config.yaml"
      ssh -o "StrictHostKeyChecking=no" -l $ssh_username $ip "sudo mkdir -p /etc/rancher/rke2 && \
        sudo echo \"server: https://${node1_ip}:9345\" > /etc/rancher/rke2/config.yaml && \
        sudo echo \"token: $rke2_token\" >> /etc/rancher/rke2/config.yaml"
    fi
    echo "Installing RKE2..."
    ssh -o "StrictHostKeyChecking=no" -l $ssh_username $ip curl -sfL https://get.rke2.io -o /tmp/install.sh; INSTALL_RKE2_CHANNEL=${downstream_kubernetes_version} sh /tmp/install.s
    echo "Enabling and starting service..."
    ssh -o "StrictHostKeyChecking=no" -l $ssh_username $ip "sudo systemctl enable rke2-server.service && sudo systemctl start rke2-server.service"
    echo "Giving time to spin up..."
    sleep 15
    echo "Done"
}

do_install true $node1_ip "Node 1"
sleep 5
do_install false $node2_ip "Node 2"
sleep 5
do_install false $node3_ip "Node 3"
sleep 5
echo "Giving extra spin up time..."
sleep 10
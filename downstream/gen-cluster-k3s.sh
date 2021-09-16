#!/bin/bash

. ../buildconfig.sh
. gen-cluster-common.sh

k3s_token=$(date +%s | sha256sum | base64 | head -c 16 ; echo)

function do_install() {
    local first_node=$1
    local ip=$2
    local cmdargs=""
    echo ""
    echo "Installing on $3"
    if [[ $first_node == "true" ]]; then
      cmdargs="--cluster-init"
    else
      cmdargs="--server https://${node1_ip}:6443"
    fi
    ssh -o "StrictHostKeyChecking=no" -l $ssh_username $ip "curl -sfL https://get.k3s.io -o /tmp/install.sh; sudo INSTALL_K3S_CHANNEL=${downstream_kubernetes_version} K3S_TOKEN=${k3s_token} sh /tmp/install.sh $cmdargs"
    echo "Done"
}

do_install true $node1_ip "Node 1"
sleep 5
do_install false $node2_ip "Node 2"
sleep 5
do_install false $node3_ip "Node 3"
sleep 5
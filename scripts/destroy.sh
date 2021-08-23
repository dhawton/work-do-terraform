#!/bin/bash

. buildconfig.sh

function clean_downstream() {
    cd downstream
    node1=$(cat terraform.tfstate | jq -r '.outputs.node1_ip.value')
    node2=$(cat terraform.tfstate | jq -r '.outputs.node2_ip.value')
    node3=$(cat terraform.tfstate | jq -r '.outputs.node3_ip.value')
    cleanup="https://raw.githubusercontent.com/rancherlabs/support-tools/master/extended-rancher-2-cleanup/extended-cleanup-rancher2.sh"

    rke remove
    cd ..

    echo ""
    echo "Cleaning node 1"
    ssh -o StrictHostKeyChecking=no -l $ssh_username $node1 "curl $cleanup | sudo bash -"
    echo ""
    echo "Cleaning node 2"
    ssh -o StrictHostKeyChecking=no -l $ssh_username $node2 "curl $cleanup | sudo bash -"
    echo ""
    echo "Cleaning node 3"
    ssh -o StrictHostKeyChecking=no -l $ssh_username $node3 "curl $cleanup | sudo bash -"
    echo "Done"
}

function destroy_downstream() {
    echo ""
    echo "Destroying downstream"
    cd downstream
    terraform destroy
    cd ..
    echo "Done"
}

function destroy_upstream() {
    echo "Destroying upstream"
    terraform destroy
    echo "Done"
}

if [[ -z "${*}" ]]; then
    destroy_downstream
    destroy_upstream
else
    "${*}"
fi
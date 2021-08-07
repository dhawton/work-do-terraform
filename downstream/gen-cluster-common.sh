#!/bin/bash

node1_name=$(cat terraform.tfstate | jq -r '.outputs.node1_name.value')
node1_ip=$(cat terraform.tfstate | jq -r '.outputs.node1_ip.value')
node1_internal_ip=$(cat terraform.tfstate | jq -r '.outputs.node1_internal_ip.value')
node2_name=$(cat terraform.tfstate | jq -r '.outputs.node2_name.value')
node2_ip=$(cat terraform.tfstate | jq -r '.outputs.node2_ip.value')
node2_internal_ip=$(cat terraform.tfstate | jq -r '.outputs.node2_internal_ip.value')
node3_name=$(cat terraform.tfstate | jq -r '.outputs.node3_name.value')
node3_ip=$(cat terraform.tfstate | jq -r '.outputs.node3_ip.value')
node3_internal_ip=$(cat terraform.tfstate | jq -r '.outputs.node3_internal_ip.value')

if [[ -f "cluster.rkestate" ]]; then
  echo "rkestate exists, this might be bad?"
  rm cluster.rkestate
fi
if [[ -f "kube_config_cluster.yml" ]]; then
  echo "kube config exists, this might be bad?"
  rm kube_config_cluster.yml
fi

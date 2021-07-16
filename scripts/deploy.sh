#!/bin/bash

script=$(readlink -f "$0")
mypath=$(dirname "$script")

. $mypath/common.sh
. buildconfig.sh

check_exists terraform
check_exists kubectl
check_exists helm

terraform init
terraform apply

if [[ $? -ne "0" ]]; then
  echo "Terraform doesn't appear to have exited cleanly"
  exit 1
fi

echo "Waiting for cloud-init to complete..."
ssh_cmd="echo 1"

if [[ $use_rke == "y" ]]; then
  ssh_cmd="docker container ls"
fi

sleep 10

while true; do
    ssh -o \"StrictHostKeyChecking=no\" -l $ssh_username ${instance_name}.do.support.rancher.space $ssh_cmd &>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "SSH appears ready to move on"
        break
    fi
    sleep 5
done

if [[ $use_rke == "y" ]]; then
  cd rke
  bash gen-cluster.sh $instance_name do.support.rancher.space $ssh_username $install_rancher
else
  echo "Not configured to use RKE... so we're done here."
  echo "Server is up at ${instance_name}.do.support.rancher.space"
fi
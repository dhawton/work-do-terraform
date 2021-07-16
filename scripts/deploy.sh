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

hostname=$(cat .instance_name)

waiting=1

echo "Waiting for cloud-init to complete..."

if [[ $use_rke == "y" ]]; then
  ssh_cmd="docker container ls"
else
  ssh_cmd="echo 1"
fi

sleep 10

while [[ $waiting == 1 ]]; do
    ssh -o \"StrictHostKeyChecking=no\" -l $(cat .ssh_user) ${hostname}.do.support.rancher.space $ssh_cmd &>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "SSH appears ready to move on"
        break
    fi
    sleep 5
done

if [[ $use_rke == "y" ]]; then
  cd rke
  bash gen-cluster.sh $hostname do.support.rancher.space $ssh_username $install_rancher
else
  echo "Not configured to use RKE... so we're done here."
  echo "Server is up at ${hostname}.do.support.rancher.space"
fi
#!/bin/bash

script=$(readlink -f "$0")
mypath=$(dirname "$script")

. $mypath/common.sh

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

echo "Waiting for docker to be installed..."

sleep 10

while [[ $waiting == 1 ]]; do
    ssh -o "StrictHostKeyChecking=no" -l $(cat .ssh_user) ${hostname}.do.support.rancher.space docker container ls &>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "SSH and Docker appear ready, moving to RKE phase"
        break
    fi
    sleep 5
done

cd rke
bash gen-cluster.sh $hostname do.support.rancher.space
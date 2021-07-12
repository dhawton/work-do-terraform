#!/bin/bash

. common.sh

check_exists terraform
check_exists kubectl
check_exists helm

terraform init
terraform apply
hostname=$(cat .instance_name)

waiting=true

echo "Waiting for docker to be installed..."

while waiting; do
    ssh -l $(cat .ssh_user) ${hostname}.do.support.rancher.space docker container ls &>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "SSH and Docker appears ready, moving to RKE phase"
        waiting=false
    fi
done

cd rke
bash gen-cluster.sh $hostname do.support.rancher.space
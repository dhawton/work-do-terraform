#!/bin/bash

script=$(readlink -f "$0")
mypath=$(dirname "$script")

. $mypath/common.sh
. $mypath/rancher.sh
. buildconfig.sh

check_exists terraform
check_exists kubectl
check_exists helm

if [[ $auto_deploy_downstream == "y" ]]; then
  check_exists rancher
  if [[ $downstream_type == "rke" ]]; then
    check_exists rke
  fi
fi

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
    ssh -o "StrictHostKeyChecking=no" -l $ssh_username ${instance_name}.${domain_name} $ssh_cmd &>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "SSH appears ready to move on"
        break
    fi
    sleep 5
done

if [[ $use_rke == "y" ]]; then
  cd rke
  bash gen-cluster.sh $instance_name $ssh_username $install_rancher
  set_rancher_admin_password ${instance_name}.${domain_name} ${rancher_admin_password}
  if [[ $auto_deploy_downstream == "y" ]]; then
    cd downstream
    terraform init
    terraform apply
    if [[ $downstream_type == "rke" ]]; then
      echo "Deploying RKE"
      bash gen-cluster-rke.sh
      get_rancher_token ${instance_name}.${domain_name} ${rancher_admin_password} ranchertoken
      echo "Creating cluster in Rancher"
      create_import_cluster ${instance_name}.${domain_name} $ranchertoken clusterid
      get_registration_token ${instance_name}.${domain_name} $ranchertoken $clusterid filepath
      echo "Importing cluster"
      KUBECONFIG=downstream/kube_config_cluster.yml kubectl apply -f $filepath
      "Done"
    fi
  fi
else
  echo "Not configured to use RKE... so we're done here."
  echo "Server is up at ${instance_name}.${domain_name}"
fi
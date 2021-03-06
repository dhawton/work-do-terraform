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

function deploy_upstream() {
  echo "Deploying upstream"
  terraform init
  terraform apply

  if [[ $? -ne "0" ]]; then
    echo "Terraform apply failed"
    exit 1
  fi

  echo ""
  echo "Waiting for cloud-init to complete..."
  ssh_cmd="echo 1"

  #sleep 10

  while true; do
      ssh -o "StrictHostKeyChecking=no" -l $ssh_username ${instance_name}.${domain_name} $ssh_cmd &>/dev/null
      if [[ $? -eq 0 ]]; then
          echo "SSH appears ready to move on"
          break
      fi
      #sleep 5
  done

  if [[ $build_upstream == "y" ]]; then
    install_rancher
    if [[ $auto_deploy_downstream == "y" ]]; then
      deploy_downstream
    fi
  else
    echo ""
    echo "We seem to be done here."
  fi
}

function install_rancher() {
  echo ""
  echo "Building upstream cluster"
  cd upstream
  bash gen-cluster.sh
  cd ..

  echo ""
  echo "Setting Rancher Password"
  set_rancher_admin_password ${instance_name}.${domain_name} ${rancher_admin_password}
  get_password

  echo ""
  echo "Rancher install completed."
}

function get_password() {
  if [[ -f "rancher_admin_password" ]]; then
    rancher_admin_password=$(cat rancher_admin_password)
  fi
}

function wait_for_nodes() {
  node1=$(cat terraform.tfstate | jq -r '.outputs.node1_ip.value')
  node2=$(cat terraform.tfstate | jq -r '.outputs.node2_ip.value')
  node3=$(cat terraform.tfstate | jq -r '.outputs.node3_ip.value')
  node1_ready=false
  node2_ready=false
  node3_ready=false
  ssh_cmd="echo 1"

  echo ""
  echo "Waiting for nodes to be ready..."

  if [[ $downstream_type == "rke" ]]; then
    ssh_cmd="docker container ls"
  fi

  while true; do
    if [[ $node1_ready == "false" ]]; then
      ssh -o "StrictHostKeyChecking=no" -l $ssh_username $node1 $ssh_cmd &>/dev/null
      if [[ $? -eq 0 ]]; then
        echo "Node 1 is ready"
        node1_ready=true
      fi
    fi
    if [[ $node2_ready == "false" ]]; then
      ssh -o "StrictHostKeyChecking=no" -l $ssh_username $node2 $ssh_cmd &>/dev/null
      if [[ $? -eq 0 ]]; then
        echo "Node 2 is ready"
        node2_ready=true
      fi
    fi
    if [[ $node3_ready == "false" ]]; then
      ssh -o "StrictHostKeyChecking=no" -l $ssh_username $node3 $ssh_cmd &>/dev/null
      if [[ $? -eq 0 ]]; then
        echo "Node 3 is ready"
        node3_ready=true
      fi
    fi
    if [[ $node1_ready == "true" ]] && [[ $node2_ready == "true" ]] && [[ $node3_ready == "true" ]]; then
      break
    fi
    sleep 5
  done
}

function deploy_downstream() {
  echo ""
  echo "Deploying Downstream Cluster"
  cd downstream
  if [[ $downstream_type == "rke2" ]]; then
    mv rke2-lb.tf.tmpl rke2-lb.tf
  fi
  terraform init
  terraform apply

  wait_for_nodes
  cd ..
  install_downstream
}

function install_downstream() {
  echo ""
  echo "Installing downstream"
  cd downstream
  if [[ $downstream_type == "rke" ]]; then
    echo "Deploying RKE"
    bash gen-cluster-rke.sh
    get_rancher_token ${instance_name}.${domain_name} ${rancher_admin_password} ranchertoken
    echo "Creating cluster in Rancher"
    create_import_cluster ${instance_name}.${domain_name} $ranchertoken clusterid
    get_registration_token ${instance_name}.${domain_name} $ranchertoken $clusterid filepath
    echo "Importing cluster"
    KUBECONFIG=kube_config_cluster.yml kubectl apply -f $filepath
    echo "Done, will take a few minutes to spin up appropriate agents"
  elif [[ $downstream_type == "k3s" ]]; then
    echo "Deploying K3S"
    bash gen-cluster-k3s.sh
    get_rancher_token ${instance_name}.${domain_name} ${rancher_admin_password} ranchertoken
    echo "Creating cluster in Rancher"
    create_import_cluster ${instance_name}.${domain_name} $ranchertoken clusterid
    get_registration_token ${instance_name}.${domain_name} $ranchertoken $clusterid filepath
    echo "Importing cluster"
    scp -o "StrictHostKeyChecking=no" $filepath $ssh_username@$node1:/tmp/manifest.yml
    ssh -o "StrictHostKeyChecking=no" -l $ssh_username $node1 k3s kubectl apply -f /tmp/manifest.yml && rm /tmp/manifest.yml
  elif [[ $downstream_type == "rke2" ]]; then
    echo "Deploying RKE2"
    bash gen-cluster-rke2.sh
    get_rancher_token ${instance_name}.${domain_name} ${rancher_admin_password} ranchertoken
    echo "Creating cluster in Rancher"
    create_import_cluster ${instance_name}.${domain_name} $ranchertoken clusterid
    get_registration_token ${instance_name}.${domain_name} $ranchertoken $clusterid filepath
    echo "Importing cluster"
    scp -o "StrictHostKeyChecking=no" $filepath $ssh_username@$node1:/tmp/manifest.yml
    ssh -o "StrictHostKeyChecking=no" -l $ssh_username $node1 sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml apply -f /tmp/manifest.yml
  fi
}

function post_wrap() {
  if [[ $build_upstream == "y" ]]; then
    echo ""
    echo "Rancher is ready at ${instance_name}.${domain_name}"
    echo "Admin password $rancher_admin_password"
  else
    echo ""
    echo "We are done."
  fi
}

if [[ $rancher_admin_password == "" ]]; then
  get_password
fi

if [[ -z "${*}" ]]; then
  deploy_upstream
else
  "${*}"
fi

post_wrap
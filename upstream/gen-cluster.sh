#!/bin/bash

. ../buildconfig.sh

ipv4=$(cat ../terraform.tfstate | jq -r '.outputs.rancher_ip.value')

ssh-keygen -f "$HOME/.ssh/known_hosts" -R "${instance_name}.${domain_name}" &>/dev/null
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$ipv4" &>/dev/null

kubernetes_version="stable"
if [[ ${k8s_version} != "latest" ]]; then
  kubernetes_version=$k8s_version
fi

k3s_token=$(date +%s | sha256sum | base64 | head -c 16 ; echo)

function do_ssh() {
  ssh -o "StrictHostKeyChecking=no" -l $ssh_username $ipv4 $@
}

echo "Installing k3s"
do_ssh curl -sfL https://get.k3s.io -o /tmp/install.sh; INSTALL_K3S_CHANNEL=${downstream_kubernetes_version} K3S_TOKEN=${k3s_token} sh /tmp/install.sh --cluster-init
echo "Getting kubeconfig"
kubeconfig=$(do_ssh sudo cat /etc/rancher/k3s/k3s.yaml | sed 's/127.0.0.1/$ipv4')
if [[ $? -ne 0 ]]; then
  echo "Failed to get kubeconfig"
  exit 1
fi
echo $kubeconfig > kubeconfig.yml

echo "Saved to kubeconfig.yml"

if [[ $install_rancher == "n" ]]; then
  echo "Not configured to install rancher, we're done here."
  exit 0
fi

echo "Handling off to install-rancher.sh"
bash install-rancher.sh
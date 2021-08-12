#!/bin/bash

. ../buildconfig.sh

function kc() {
  kubectl --kubeconfig=kubeconfig.yml $@
}

function hlm() {
  KUBECONFIG=./kubeconfig.yml helm $@
}

function log() {
  echo ""
  echo "$@"
}

chmod 600 kube_config_cluster.yml

log "Adding rancher chart, likely to already exist..."
hlm repo add rancher-latest https://releases.rancher.com/server-charts/latest

log "Creating cattle-system namespace"
kc create namespace cattle-system

log "Creating secret"
kc -n cattle-system create secret tls tls-rancher-ingress --cert=$rancher_cert --key=$rancher_key

if [[ ! -z "$rancher_ca" ]]; then
  log "Creating CA secret"
  kc -n cattle-system create secret generic tls-ca --from-file=cacerts.pem=${rancher_ca}
fi

rancher_arg=""
if [[ $rancher_version != "latest" ]]; then
  rancher_arg="--version ${rancer_version}"
fi

if [[ ! -z "$rancher_ca" ]]; then
  rancher_arg="--set privateCA=true ${rancher_arg}"
fi

log "Installing Rancher from charts"
hlm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=${instance_name}.${domain_name} \
  --set replicas=1 \
  --set ingress.tls.source=secret \
  $ranger_arg

log "Waiting for Rancher deployment"
kc -n cattle-system rollout status deploy/rancher

log "Done."
echo "You can access the install at https://${instance_name}.${domain_name}"

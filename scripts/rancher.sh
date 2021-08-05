#!/bin/bash

function set_rancher_admin_password() {
    rancher_api=$1
    admin_password=$2
    if [[ -z "$admin_password" ]]; then
        echo "Warning: admin password not provided"
        admin_password=$(openssl rand -base64 16)
        echo "--- Using admin password: $admin_password"
    fi

    login_token=$(curl -ks "https://$rancher_api/v3-public/localProviders/local?action=login" -H "Content-Type: application/json" -d '{"username":"admin", "password":"admin"}' | jq -r '.token')
    if [[ -z "$login_token" ]]; then
        echo "Error: Failed to login to Rancher"
        exit 1
    fi

    curl -ks "https://$rancher_api/v3/users?action=changePassword" -H "Content-Type: application/json" -d '{"oldPassword":"admin", "newPassword":"'"${admin_password}"'"}' -H "Authorization: Bearer $login_token"
    curl -ks "https://$rancher_api/v3/settings/server-url" -H "Content-Type: application/json" -d '{"url":"https://'"${rancher_api}"'"}' -H "Authorization: Bearer $login_token"
}

function get_rancher_token() {
    rancher_api=$1
    admin_password=$2
    local __resultvar=$2
    login_token=$(curl -ks "https://$rancher_api/v3-public/localProviders/local?action=login" -H "Content-Type: application/json" -d '{"username":"admin", "password":"admin"}' | jq -r '.token')
    if [[ -z "$login_token" ]]; then
        echo "Error: Failed to login to Rancher"
        exit 1
    fi

    apiresponse=$(curl -ks "https://$rancher_api/v3/token" -H "Authorization: Bearer $login_token" -H "Content-Type: application/json" -d '{"type":"token","description":"Autodeploy Script"}')
    apitoken=$(echo $apiresponse | jq -r '.token')

    eval $__resultvar="$apitoken"
}

function create_import_cluster() {
    rancher_api=$1
    rancher_token=$2
    local __resultvar=$3

    apiresponse=$(curl -ks "https://$rancher_api/v3/cluster" \
        -X PUT \
        -H "Authorization: Bearer $rancher_token" \
        -H "Content-Type: application/json" \
        -d '{"dockerRootDir":"/var/lib/docker","enableClusterAlerting":false,"enableClusterMonitoring":false,"enableNetworkPolicy":false,"windowsPreferedCluster":false,"type":"cluster","name":"imported","agentEnvVars":[],"labels":{},"annotations":{}}')

    eval $__resultvar=$(echo $apiresponse | jq -r '.id')
}

function get_registration_token() {
    rancher_api=$1
    rancher_token=$2
    cluster_id=$3
    local __resultvar=$4

    apiresponse=$(curl -ks "https://$rancher_api/v3/clusterregistrationtoken" \
        -X POST \
        -H "Authorization: Bearer $rancher_token" \
        -H "Content-Type: application/json" \
        -d '{"clusterId":"'"$cluster_id"'","type":"clusterRegistrationToken"}'
    )
    manifest=$(echo $apiresponse | jq -r '.manifestUrl')
    curl -ksfL "$manifest"
    eval $__resultvar=$manifest
}
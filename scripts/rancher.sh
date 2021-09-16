#!/bin/bash

defaultPass="admin"

function generate_password() {
    date +%s | sha256sum | base64 | head -c 32 ; echo
}

function set_rancher_admin_password() {
    rancher_api=$1
    admin_password=$2
    if [[ -z "$admin_password" ]]; then
        echo "Warning: admin password not provided"
        admin_password=$(generate_password)
        echo "--- Using admin password: $admin_password"
    fi

    echo $admin_password > rancher_admin_password

    login_response=$(curl -ks "https://$rancher_api/v3-public/localProviders/local?action=login" -H "Content-Type: application/json" -d '{"username":"admin", "password":"'"$defaultPass"'"}')
    login_token=$(echo $login_response | jq -r '.token')
    if [[ -z "$login_token" ]]; then
        echo "Error: Failed to login to Rancher"
        echo "Debug: $login_response"
        exit 1
    fi

    curl -ks "https://$rancher_api/v3/users?action=changepassword" -H "Content-Type: application/json" -d '{"currentPassword":"'"$defaultPass"'", "newPassword":"'"${admin_password}"'"}' -H "Authorization: Bearer $login_token"
    curl -ks "https://$rancher_api/v3/settings/server-url" -X PUT -H "Content-Type: application/json" -d '{"name":"server-url","value":"https://'"${rancher_api}"'"}' -H "Authorization: Bearer $login_token"
}

function get_rancher_token() {
    rancher_api=$1
    admin_password=$2
    local __resultvar=$3
    login_token=$(curl -ks "https://$rancher_api/v3-public/localProviders/local?action=login" -X POST -H "Content-Type: application/json" -d '{"username":"admin", "password":"'"$admin_password"'"}' | jq -r '.token')
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
        -X POST \
        -H "Authorization: Bearer $rancher_token" \
        -H "Content-Type: application/json" \
        -d '{"dockerRootDir":"/var/lib/docker","enableClusterAlerting":false,"enableClusterMonitoring":false,"enableNetworkPolicy":false,"windowsPreferedCluster":false,"type":"cluster","name":"imported","agentEnvVars":[],"labels":{},"annotations":{}}')

    cluster_id=$(echo $apiresponse | jq -r '.id')
    eval $__resultvar="$cluster_id"
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
    curl -v -ksfL "$manifest" -o manifest.yml
    eval $__resultvar="manifest.yml"
}
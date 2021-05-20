#!/bin/bash

# Fetch github public keys and setup ~/.ssh/authorized_keys
# Arguments: username
function setup_authorized_keys() {
    authorized_keys_file="/home/$${1}/.ssh/authorized_keys"
    ssh_dir=$(dirname "$${authorized_keys_file}")

    mkdir -p "$${ssh_dir}"
    chmod 700 "$${ssh_dir}"
    touch "$${authorized_keys_file}"
    chmod 600 "$${authorized_keys_file}"
    chown -R $${1}:$${1} "$${ssh_dir}"

    echo "$${authorized_keys_file}"
    return 0
}

# Add an ssh key
# Arguments: authorized_keys file, username, key, comment
function add_ssh_key() {
    echo "Adding key for $${2} to $${1} - $${3}"
    echo "$${3} $${4}" >> "$${1}"

    return 0
}

# Use GitHub API to get public keys
# Arguments: Github username, authorized_keys_file
function get_github_keys() {
    for row in $(curl -s https://api.github.com/users/$${1}/keys | jq -r '.[] | @base64'); do
        pubkey=$(echo "$${row}" | base64 --decode | jq -rc '.key')
        add_ssh_key "$${2}" "$${1}" "$${pubkey}" "Retrieved from GitHub"
    done

    return 0
}

echo "Configuring ssh keys."

%{ for user in ssh_users ~}
echo "Configuring ssh keys for ${user.username}."
authorized_keys_file=$(setup_authorized_keys "${user.username}")
get_github_keys "${user.github_username}" "$${authorized_keys_file}"
%{ endfor ~}

echo "Done."

echo "Configuring hostname."
hostnamectl set-hostname "$${hostname}"
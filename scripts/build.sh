#!/bin/bash

script=$(readlink -f "$0")
mypath=$(dirname "$script")

. $mypath/common.sh
. $mypath/defaults.sh

project=$1
basedir="$HOME/work/terraform/"
baserepo="https://github.com/dhawton/work-do-terraform"
do_token_file="$HOME/.digitalocean"
cloudflare_token_file="$HOME/.cloudflare"

if [[ $project == "" ]]; then
  read -p "Project name: " project
fi

if [[ ! -d $basedir ]]; then
  mkdir -p $basedir
fi

if [[ -d "$basedir$project" ]]; then
  echo "Directory $basedir$project exists, cannot continue with building..."
  exit 1
fi

check_exists git

echo "Cloning base..."

git clone "$baserepo" $basedir$project

cd $basedir$project

do_token=""
cloudflare_token=""

if [[ -f $do_token_file ]]; then
  echo "Found digital ocean key where expected, loading"
  do_token=$(cat $do_token_file)
fi

if [[ -f $cloudflare_token_file ]]; then
  echo "Found cloudflare key where expected, loading"
  cloudflare_token=$(cat $cloudflare_token_file)
fi

echo "Configuration time:"

if [[ $do_token == "" ]]; then
  do_prompt "Digital Ocean Token" "" do_token
  if [[ $do_token == "" ]]; then
    echo "Digital Ocean token cannot be blank"
    exit 1
  fi
  do_promptyn "Save token to $do_token_file?" "n" do_save_token
  if [[ $do_save_token == "y" ]]; then
    echo "Saving token to $do_token_file"
    echo $do_token > $do_token_file
  fi
fi

if [[ $cloudflare_token == "" ]]; then
  do_prompt "Cloudflare Token" "" cloudflare_token
  if [[ $cloudflare_token == "" ]]; then
    echo "Cloudflare token cannot be blank"
    exit 1
  fi
  do_promptyn "Save token to $cloudflare_token_file?" "n" do_save_token
  if [[ $do_save_token == "y" ]]; then
    echo "Saving token to $cloudflare_token_file"
    echo $cloudflare_token > $cloudflare_token_file
  fi
fi

do_prompt "Instance Name" $default_instance_name instance_name
do_prompt "Domain" $default_domain_name domain_name
do_prompt "Instance Type" $default_instance_type instance_type
do_prompt "Instance Image" $default_instance_image instance_image
do_prompt "Instance Region" $default_instance_region instance_region
do_promptyn "Use RKE?" $default_use_rke use_rke
if [[ $use_rke == "y" ]]; then
  do_prompt "Kubernetes Version" $default_k8s_version k8s_version
  do_promptyn "Install Rancher" $default_install_rancher install_rancher
  if [[ $install_rancher == "y" ]]; then
    do_prompt "Rancher Version" $default_rancher_version rancher_version
  fi
else
  install_rancher="n"
fi
do_prompt "SSH Username" $default_ssh_username ssh_username
do_prompt "SSH Key" $default_ssh_key ssh_key
do_prompt "GitHub Username for SSH public keys" $default_github_username github_username
do_prompt "Rancher Admin password, blank for random" "$default_rancher_admin_password" rancher_admin_password
do_promptyn "Auto-deploy downstream cluster?" $default_auto_deploy_downstream auto_deploy_downstream
if [[ $auto_deploy_downstream == "y" ]]; then
  do_prompt_choices "Downstream type (rke, k3s, rke2)" $default_downstream_type downstream_type rke rke2 k3s
  do_prompt "Node prefix" $default_node_prefix node_prefix
fi

cat >variables_override.tf <<!VARIABLES!OVERRIDE!
# Name of the instance
variable "instance_name" {
    default = "$instance_name"
}

# Type of VM
variable "instance_type" {
    default = "$instance_type"
}

# Image to use
variable "instance_image" {
    default = "$instance_image"
}

# Instance Region
variable "instance_region" {
    default = "$instance_region"
}

# Users
variable "ssh_users" {
    default = [
        {
            username = "$ssh_username"
            shell = "/bin/bash" 
            sudo = true
            github_username = "$github_username"
        }
    ]
}

variable "rootdomain" {
    default = "$domain_name"
}
!VARIABLES!OVERRIDE!

if [[ $auto_deploy_downstream == "y" ]]; then
  cat >downstream/variables_override.tf <<!VARIABLES!OVERRIDE!
# Node prefix
variable "node_prefix" {
    default = "$node_prefix"
}

# Type of VM
variable "instance_type" {
    default = "$instance_type"
}

# Image to use
variable "instance_image" {
    default = "$instance_image"
}

# Instance Region
variable "instance_region" {
    default = "$instance_region"
}

# Users
variable "ssh_users" {
    default = [
        {
            username = "$ssh_username"
            shell = "/bin/bash" 
            sudo = true
            github_username = "$github_username"
        }
    ]
}

variable "rootdomain" {
    default = "$domain_name"
}
!VARIABLES!OVERRIDE!

  cat >downstream/terraform.tfvars <<!TFVARS!
do_token = "$do_token"
!TFVARS!

  if [[ $downstream_type != "rke" ]]; then
    cat >>downstream/variables_override.tf <<!VARIABLES!OVERRIDE!
variable "install_docker" {
    default = false
}
!VARIABLES!OVERRIDE!
  fi
fi

cat >terraform.tfvars <<!TFVARS!
do_token = "$do_token"
cloudflare_api_token = "$cloudflare_token"
!TFVARS!

cat >buildconfig.sh <<!VARIABLES!OVERRIDE!
instance_name=$instance_name
domain_name=$domain_name
ssh_username=$ssh_username
ssh_key=$ssh_key
use_rke=$use_rke
k8s_version=$k8s_version
install_rancher=$install_rancher
rancher_version=$rancher_version
rancher_admin_password=$rancher_admin_password
auto_deploy_downstream=$auto_deploy_downstream
downstream_type=$downstream_type
!VARIABLES!OVERRIDE!

do_promptyn "Do you wish to deploy now?" "n" do_deploy
if [[ $do_deploy == "y" ]]; then
  echo "Deploying"
  $mypath/deploy.sh
else
  echo "To continue, cd $basedir$project and run the deployer"
fi

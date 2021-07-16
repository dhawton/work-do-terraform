#!/bin/bash

script=$(readlink -f "$0")
mypath=$(dirname "$script")

. $mypath/common.sh

project=$1
basedir="$HOME/work/terraform/"

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

git clone https://github.com/dhawton/work-do-terraform $basedir$project

cd $basedir$project

do_token=""

if [[ -f "$HOME/.digitalocean" ]]; then
  echo "Found digital ocean key where expected, loading"
  do_token=$(cat $HOME/.digitalocean)
fi

echo "Configuration time:"

if [[ $do_token == "" ]]; then
  do_prompt "Digital Ocean Token" "" do_token
  if [[ $do_token == "" ]]; then
    echo "Digital Ocean token cannot be blank"
    exit 1
  fi
fi

do_prompt "Instance Name" "daniel-rancher" instance_name
do_prompt "Instance Type" "s-2vcpu-4gb" instance_type
do_prompt "Instance Image" "ubuntu-18-04-x64" instance_image
do_prompt "Instance Region" "sfo3" instance_region
do_promptyn "Use RKE?" "y" use_rke
if [[ $use_rke == "y" ]]; then
  do_promptyn "Install Rancher" "y" install_rancher
else
  install_rancher="n"
fi
do_prompt "SSH Username" "daniel" ssh_username
do_prompt "GitHub Username for SSH public keys" "dhawton" github_username

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
!VARIABLES!OVERRIDE!

cat >terraform.tfvars <<!TFVARS!
do_token = "$do_token"
!TFVARS!

cat >buildconfig.sh <<!VARIABLES!OVERRIDE!
instance_name=$instance_name
ssh_username=$ssh_username
use_rke=$use_rke
install_rancher=$install_rancher
!VARIABLES!OVERRIDE!

echo $instance_name > .instance_name
echo $ssh_username > .ssh_user

echo "To continue, cd $basedir$project and run the deployer"
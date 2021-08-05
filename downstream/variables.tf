locals {
    rootdomain = var.rootdomain != "" ? var.rootdomain : "do.support.rancher.space"
}

variable "node_prefix" {
    type = string
    description = "Prefix for worker nodes"
    default = "node"
}

variable "instance_type" {
    type = string
    description = "Instance type from Linode"
    default = "s-2vcpu-4gb"
}

variable "instance_image" {
    type = string
    description = "Operating System"
    default = "ubuntu-18-04-x64"
}

variable "instance_testing" {
    type = bool
    description = "Should we use the testing apt repos"
    default = false
}

variable "debugging" {
    type = bool
    description = "Should be used: almost never"
    default = false
}

variable "instance_region" {
    type = string
    description = "Region"
    default = "sfo3"
}

variable "ssh_users" {
    type = list(object({
        username = string
        shell = string
        sudo = bool
        github_username = string
    }))
    default = [
        {
            username = "localuser"
            shell = "/bin/bash"
            sudo = false
            github_username = ""
        }
    ]
    description = "List of ssh users to setup"
}

variable "rootdomain" {
    type = string
    description = "Domain to use"
    default = "do.support.rancher.space"
}

variable "install_docker" {
    type = bool
    description = "Should we install docker"
    default = true
}
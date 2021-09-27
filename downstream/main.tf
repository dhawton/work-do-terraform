terraform {
    required_providers {
        digitalocean = {
            source = "digitalocean/digitalocean"
        }
        cloudflare = {
            source = "cloudflare/cloudflare"
        }
    }
}

provider "digitalocean" {
  token = var.do_token
}
provider "cloudflare"{
    api_token = var.cloudflare_api_token
}

resource "digitalocean_droplet" "node01" {
    name = "${var.node_prefix}-node01"
    image = var.instance_image
    region = var.instance_region
    size = var.instance_type
    user_data = data.template_cloudinit_config.config.rendered
    tags = [var.do_tag]
}

resource "digitalocean_droplet" "node02" {
    name = "${var.node_prefix}-node02"
    image = var.instance_image
    region = var.instance_region
    size = var.instance_type
    user_data = data.template_cloudinit_config.config.rendered
    tags = [var.do_tag]
}

resource "digitalocean_droplet" "node03" {
    name = "${var.node_prefix}-node03"
    image = var.instance_image
    region = var.instance_region
    size = var.instance_type
    user_data = data.template_cloudinit_config.config.rendered
    tags = [var.do_tag]
}

output "node1_name" {
    value = digitalocean_droplet.node01.name
}

output "node2_name" {
    value = digitalocean_droplet.node02.name
}

output "node3_name" {
    value = digitalocean_droplet.node03.name
}

output "node1_ip" {
    value = digitalocean_droplet.node01.ipv4_address
}

output "node1_internal_ip" {
    value = digitalocean_droplet.node01.ipv4_address_private
}

output "node2_ip" {
    value = digitalocean_droplet.node02.ipv4_address
}

output "node2_internal_ip" {
    value = digitalocean_droplet.node02.ipv4_address_private
}

output "node3_ip" {
    value = digitalocean_droplet.node03.ipv4_address
}

output "node3_internal_ip" {
    value = digitalocean_droplet.node03.ipv4_address_private
}

variable "do_token" {}

variable "cloudflare_api_token" {}
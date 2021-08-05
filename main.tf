terraform {
    required_providers {
        cloudflare = {
            source = "cloudflare/cloudflare"
        }
        digitalocean = {
            source = "digitalocean/digitalocean"
        }
    }
}

provider "cloudflare"{
    api_token = var.cloudflare_api_token
}

provider "digitalocean" {
    token = var.do_token
}

resource "digitalocean_droplet" "rancher" {
    name = var.instance_name
    image = var.instance_image
    region = var.instance_region
    size = var.instance_type
    private_networking = true
    user_data = data.template_cloudinit_config.config.rendered
}

resource "cloudflare_record" "rancherrecord" {
    zone_id = var.zone_id
    name = var.instance_name
    type = "A"
    value = digitalocean_droplet.rancher.ipv4_address
    ttl = 60
}

variable "do_token" {}
variable "cloudflare_api_token" {}
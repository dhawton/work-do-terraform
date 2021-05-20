terraform {
    required_providers {
        linode = {
            source = "linode/linode"
        }
    }
}

provider "linode" {
  token = var.linode_token
}

resource "linode_stackscript" "cloudinit_stackscript" {
    script = "${chomp(file("${path.module}/cloudinit/stackscript.sh"))}"
    description = "Stack Script to setup cloud-init"
    images = [
        "linode/debian10"
    ]
    is_public = false
    label = "cloud-init"
}

resource "linode_instance" "rancher" {
    label = var.instance_name
    image = var.instance_image
    region = var.instance_region
    type = var.instance_type
    private_ip = true
    stackscript_id = linode_stackscript.cloudinit_stackscript.id
    root_pass = "Temp!@#321"

    stackscript_data = {
      "userdata" = data.template_cloudinit_config.config.rendered
    }
}

resource "linode_domain_record" "rancherrecord" {
    domain_id = var.rootdomain_id
    name = var.instance_name
    record_type = "A"
    target = linode_instance.rancher.ip_address
    ttl_sec = 300
}

variable "linode_token" {}
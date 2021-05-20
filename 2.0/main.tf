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
        "linode/debian10",
        "linode/debian9",
        "linode/ubuntu18.04",
        "linode/ubuntu20.04"
    ]
    is_public = false
    label = "cloud-init"
}

resource "linode_instance" "rancher" {
    image = var.instance_image
    region = var.instance_region
    type = var.instance_type
    private_ip = true
    stackscript_id = linode_stackscript.cloudinit_stackscript.id

    stackscript_data = {
      "userdata" = data.template_cloudinit_config.config.rendered
    }
}

resource "linode_domain_record" "rancherrecord" {
    domain_id = var.rootdomain_id
    name = var.instance_name
    record_type = "A"
    target = linode_instance.rancher.ip_address
}

variable "linode_token" {}
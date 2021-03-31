data "template_file" "cloud-init-yaml" {
  template = file("${path.module}/files/cloud-init.yaml")
  vars = {
    init_ssh_public_key = file(var.pub_key_file)
  }
}

resource "digitalocean_droplet" "rancher" {
  image = "debian-10-x64"
  name = "rancher"
  region = "sfo3"
  size = "s-2vcpu-4gb"
  private_networking = true
  ssh_keys = [
    data.digitalocean_ssh_key.terraform.id
  ]
  user_data = data.template_file.cloud-init-yaml.rendered
}

resource "digitalocean_record" "rancher" {
  domain = "crowk.com"
  type = "A"
  name = "rancher"
  ttl = 180
  value = digitalocean_droplet.rancher.ipv4_address
}

output "public_ip_server" {
  value = digitalocean_droplet.rancher.ipv4_address
}

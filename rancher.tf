resource "digitalocean_droplet" "rancher" {
  image = "debian-10-x64"
  name = "rancher"
  region = "sfo3"
  size = "s-2vcpu-4gb"
  private_networking = true
  ssh_keys = [
    data.digitalocean_ssh_key.terraform.id
  ]
  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.pvt_key)
    timeout = "2m"
  }
  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "sudo apt-get update",
      "sudo apt upgrade -y",
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release",
      "curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io",
      "sudo docker run -d --restart=unless-stopped -p 80:80 -p 443:443 -v /opt/rancher:/var/lib/rancher --privileged rancher/rancher:latest --acme-domain rancher.crowk.com"
    ]
  }
}

resource "digitalocean_record" "rancher" {
  domain = "crowk.com"
  type = "A"
  name = "rancher"
  value = digitalocean_droplet.rancher.ipv4_address
}

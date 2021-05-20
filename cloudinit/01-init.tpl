#cloud-config

timezone: America/Los_Angeles

%{ if debugging }
disable_root: true
ssh_pwauth: false
%{ endif}

%{ if debian_testing }
# This is mostly because Debian seems to be using the old config item by default
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=967935
apt_preserve_sources_list: false

apt:
  preserve_sources_list: false
  sources_list: |
    deb $MIRROR testing main contrib non-free
    deb-src $MIRROR testing main
  conf: |
    APT {
      Get {
        Assume-Yes 'true';
        Fix-Broken 'true';
      }
    }
%{ endif }

package_update: true
package_upgrade: true
package_reboot_if_required: true

groups:
  - docker

users:
%{ for user in ssh_users ~}
  - name: ${user.username}
    sudo: ${user.sudo}
%{ if user.sudo }
    groups: [users, wheel]
    sudo: ["ALL=(ALL:ALL) NOPASSWD: ALL"]
%{ else }
    groups: [users]
    sudo: [""]
%{ endif }
    shell: ${user.shell}
%{ endfor }

packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg
  - lsb-release
  - unattended-upgrades
  - figlet
  - jq

runcmd:
  - curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  - echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io
  - systemctl start docker
  - systemctl enable docker
  - docker run -d --restart=unless-stopped -p 80:80 -p 443:443 -v /opt/rancher:/var/lib/rancher --privileged rancher/rancher:latest --acme-domain ${domain}

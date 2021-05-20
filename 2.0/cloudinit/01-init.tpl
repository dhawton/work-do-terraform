#cloud-config

timezone: America/Los_Angeles
#disable_root: true
#ssh_pwauth: false

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
  - gnupg-agent
  - unattended-upgrades
  - figlet
  - jq

runcmd:
  - curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  - bash /tmp/get-docker.sh
  - systemctl start docker
  - systemctl enable docker
  - docker run -d --restart=unless-stopped -p 80:80 -p 443:443 -v /opt/rancher:/var/lib/rancher --privileged rancher/rancher:latest --acme-domain ${domain}
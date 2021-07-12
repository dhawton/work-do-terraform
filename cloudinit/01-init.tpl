#cloud-config

timezone: America/Los_Angeles

disable_root: true
ssh_pwauth: false

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

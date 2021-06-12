#cloud-config

timezone: America/Denver

%{ if !debugging }
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

terraform {
    required_providers {
        linode = {
            source = "linode/linode"
        }
        cloudflare = {
            source = "cloudflare/cloudflare"
        }
    }
}

provider "linode" {
  token = var.linode_token
}

provider "cloudflare" {
    api_token = var.cloudflare_api_token
}

resource "linode_stackscript" "cloudinit_stackscript" {
    script = "${chomp(file("${path.module}/cloudinit/stackscript.sh"))}"
    description = "Stack Script to setup cloud-init"
    images = [
        "linode/debian10",
        "linode/ubuntu18.04",
        "linode/ubuntu20.04"
    ]
    is_public = false
    label = "cloud-init"
}

resource "linode_instance" "rancher" {
    label = "${var.instance_name}.${var.rootdomain}"
    image = var.instance_image
    region = var.instance_region
    type = var.instance_type
    private_ip = true
    stackscript_id = linode_stackscript.cloudinit_stackscript.id
    root_pass = var.debugging ? var.root_pass : ""

    stackscript_data = {
      "userdata" = data.template_cloudinit_config.config.rendered
    }
}

resource "cloudflare_record" "rancherrecord" {
    zone_id = var.rootdomain_id
    name = var.instance_name
    type = "A"
    value = linode_instance.rancher.ip_address
    ttl = 300
}

resource "cloudflare_record" "rancherAAAArecord" {
    zone_id = var.rootdomain_id
    name = var.instance_name
    type = "AAAA"
    value = replace(linode_instance.rancher.ipv6, "/128", "")
    ttl = 300
}

resource "cloudflare_record" "rancherIrecord" {
    zone_id = var.rootdomain_id
    name = "${var.instance_name}.i"
    type = "A"
    value = linode_instance.rancher.private_ip_address
    ttl = 300
}

variable "linode_token" {}
variable "root_pass" {}
variable "cloudflare_api_token" {}
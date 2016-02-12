variable "project" {}

variable "flannel_network" {
  description = "flannel network"
  default = "10.244.0.0/16"
}

resource "digitalocean_droplet" "master" {
  image = "coreos-beta"
  name = "${var.project}-k8s-master"
  region = "${var.region}"
  size = "4gb"
  private_networking = true
  ssh_keys = [
    "${var.ssh_fingerprint}"
  ]
  user_data = "${template_file.master.rendered}"

  connection {
    user = "core"
    type = "ssh"
    key_file = "${var.private_key}"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = ["/bin/true"]
  }
}

resource "template_file" "master" {
  template = "${file("${path.module}/tmpls/master.yaml")}"

  vars {
    flannel_network = "${var.flannel_network}"
  }
}

resource "digitalocean_droplet" "node" {
  count = "4"
  image = "coreos-beta"
  name = "${var.project}-k8s-node-${count.index+1}"
  region = "${var.region}"
  size = "4gb"
  private_networking = true
  ssh_keys = [
    "${var.ssh_fingerprint}"
  ]
  user_data = "${template_file.node.rendered}"

  connection {
    user = "core"
    type = "ssh"
    key_file = "${var.private_key}"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = ["/bin/true"]
  }
}

resource "template_file" "node" {
  template = "${file("${path.module}/tmpls/node.yaml")}"

  vars {
    flannel_network = "${var.flannel_network}"
    master_ip = "${digitalocean_droplet.master.ipv4_address_private}"
  }
}

output "server" {
  value = "http://${digitalocean_droplet.master.ipv4_address_public}:8080"
}

variable "project" {}

variable "etcd_peer_proto" {
  type = "string"
  default = "http"
}

variable "etcd_peer_port" {
  type = "string"
  default = "2380"
}

resource "digitalocean_droplet" "master" {
  count = "3"
  image = "coreos-beta"
  name = "${var.project}-k8s-master-${count.index+1}"
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

resource "template_file" "etcd_discovery_url" {
  template = "${file("${path.module}/etcd_discovery_url.txt")}"
}

resource "template_file" "master" {
  template = "${file("${path.module}/tmpls/master.yaml")}"

  vars {
    network = "10.244.0.0/16"
    discovery_url = "${template_file.etcd_discovery_url.rendered}"
  }
}

resource "digitalocean_droplet" "node" {
  count = "3"
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
    network = "10.244.0.0/16"
    initial_cluster = "${join(",", formatlist("%s=%s://%s:%s", digitalocean_droplet.master.*.name, var.etcd_peer_proto, digitalocean_droplet.master.*.ipv4_address_private, var.etcd_peer_port))}"
  }
}

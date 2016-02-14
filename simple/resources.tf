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
    etcd_peer_port = "${var.etcd_peer_port}"
    etcd_peer_proto = "${var.etcd_peer_proto}"
  }
}

resource "digitalocean_droplet" "node" {
  count = "${var.node_count}"
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
    etcd_peer_proto = "${var.etcd_peer_proto}"
    etcd_peer_port = "${var.etcd_peer_port}"
  }
}

output "server" {
  value = "http://${digitalocean_droplet.master.ipv4_address_public}:8080"
}

resource "null_resource" "master_etcd_tls" {
  connection {
    host = "${digitalocean_droplet.master.ipv4_address}"
    user = "core"
    type = "ssh"
    key_file = "${var.private_key}"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "cat <<EOF > /home/core/etcd.pem",
      "${tls_locally_signed_cert.master.cert_pem}",
      "EOF"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "cat <<EOF > /home/core/etcd.key",
      "${tls_private_key.master.private_key_pem}",
      "EOF"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "cat <<EOF > /home/core/ca.pem",
      "${tls_self_signed_cert.ca.cert_pem}",
      "EOF"
    ]
  }

  provisioner "file" {
    source = "scripts/install_certs.sh"
    destination = "/tmp/install_certs.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_certs.sh",
      "sudo /tmp/install_certs.sh",
      "rm /tmp/install_certs.sh"
    ]
  }
}

resource "null_resource" "node_etcd_tls" {
  count = "${var.node_count}"

  connection {
    user = "core"
    host = "${element(digitalocean_droplet.node.*.ipv4_address, count.index)}"
    type = "ssh"
    key_file = "${var.private_key}"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "cat <<EOF > /home/core/etcd.pem",
      "${element(tls_locally_signed_cert.node.*.cert_pem, count.index)}",
      "EOF"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "cat <<EOF > /home/core/etcd.key",
      "${element(tls_private_key.node.*.private_key_pem, count.index)}",
      "EOF"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "cat <<EOF > /home/core/ca.pem",
      "${tls_self_signed_cert.ca.cert_pem}",
      "EOF"
    ]
  }

  provisioner "file" {
    source = "scripts/install_certs.sh"
    destination = "/tmp/install_certs.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_certs.sh",
      "sudo /tmp/install_certs.sh",
      "rm /tmp/install_certs.sh"
    ]
  }
}


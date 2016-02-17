#####################################
# node droplets
#####################################
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
    etcd_endpoints = "${var.etcd_client_proto}://${digitalocean_droplet.master.ipv4_address_private}:${var.etcd_client_port}"
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
      "cat <<EOF > /home/core/client.pem",
      "${element(tls_locally_signed_cert.node.*.cert_pem, count.index)}",
      "EOF"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "cat <<EOF > /home/core/client.key",
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
    source = "scripts/install_certs_node.sh"
    destination = "/tmp/install_certs_node.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_certs_node.sh",
      "sudo /tmp/install_certs_node.sh",
      "rm /tmp/install_certs_node.sh"
    ]
  }
}

output "server" {
  value = "http://${digitalocean_droplet.master.ipv4_address_public}:8080"
}
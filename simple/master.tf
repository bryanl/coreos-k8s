#####################################
# Master droplet
#####################################
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
      "cat <<EOF > /home/core/client.pem",
      "${tls_locally_signed_cert.master_client.cert_pem}",
      "EOF"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "cat <<EOF > /home/core/client.key",
      "${tls_private_key.master_client.private_key_pem}",
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

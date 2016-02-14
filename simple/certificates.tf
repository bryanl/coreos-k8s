resource "tls_private_key" "node" {
  count = "${var.node_count}"
  algorithm = "RSA"
  rsa_bits "2048"
}

resource "tls_cert_request" "node" {
  count = "${var.node_count}"
  key_algorithm = "RSA"
  private_key_pem = "${element(tls_private_key.node.*.private_key_pem, count.index)}"

  subject {
    common_name = "${element(digitalocean_droplet.node.*.name, count.index)}"
    organization = "k8s simple"
  }

  ip_addresses = ["127.0.0.1", "${element(digitalocean_droplet.node.*.ipv4_address_private, count.index)}"]
  dns_names = ["${element(digitalocean_droplet.node.*.name, count.index)}", "${element(digitalocean_droplet.node.*.name, count.index)}.local"]
}

resource "tls_locally_signed_cert" "node" {
  count = "${var.node_count}"
  cert_request_pem = "${element(tls_cert_request.node.*.cert_request_pem, count.index)}"

  ca_key_algorithm = "RSA"
  ca_private_key_pem = "${tls_private_key.ca.private_key_pem}"
  ca_cert_pem = "${tls_self_signed_cert.ca.cert_pem}"

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth"
  ]
}

resource "tls_locally_signed_cert" "master" {
  cert_request_pem = "${tls_cert_request.master.cert_request_pem}"

  ca_key_algorithm = "RSA"
  ca_private_key_pem = "${tls_private_key.ca.private_key_pem}"
  ca_cert_pem = "${tls_self_signed_cert.ca.cert_pem}"

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth"
  ]
}

resource "tls_cert_request" "master" {
  key_algorithm = "RSA"
  private_key_pem = "${tls_private_key.master.private_key_pem}"

  subject {
    common_name = "${digitalocean_droplet.master.name}"
    organization = "k8s simple"
  }

  ip_addresses = ["127.0.0.1", "${digitalocean_droplet.master.ipv4_address_private}"]
  dns_names = ["${digitalocean_droplet.master.name}", "${digitalocean_droplet.master.name}"]
}

resource "tls_private_key" "master" {
  algorithm = "RSA"
  rsa_bits = "2048"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm = "RSA"
  private_key_pem = "${tls_private_key.ca.private_key_pem}"

  subject {
    common_name = "simple ca"
    organization = "k8s simple"
  }

  validity_period_hours = 12

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature"
  ]

  is_ca_certificate = true
}

resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits = "2048"
}


variable "project" {
  description = "project name"
}

variable "etcd_client_port" {
  description = "etcd client port"
  type = "string"
  default = "2379"
}

variable "etcd_client_proto" {
  description = "etcd client protocol"
  type = "string"
  default = "https"
}

variable "etcd_peer_port" {
  description = "etcd peer port"
  type = "string"
  default = "2380"
}

variable "etcd_peer_proto" {
  description = "etcd peer protocol"
  type = "string"
  default = "https"
}

variable "flannel_network" {
  description = "flannel network"
  default = "10.244.0.0/16"
}

variable "node_count" {
  description = "number of node servers"
  type = "string"
  default = "4"
}

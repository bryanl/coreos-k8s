#!/usr/bin/env bash

set -e

etcd_ssl_dir=/etc/ssl/etcd
mkdir -p $etcd_ssl_dir

# copy key and certs to their proper place
mv /home/core/ca.pem ${etcd_ssl_dir}/ca.pem
mv /home/core/etcd.pem ${etcd_ssl_dir}/etcd.pem
mv /home/core/etcd.key ${etcd_ssl_dir}/etcd.key
mv /home/core/client.pem ${etcd_ssl_dir}/client.pem
mv /home/core/client.key ${etcd_ssl_dir}/client.key

chown etcd:wheel ${etcd_ssl_dir}/*
chmod 644 ${etcd_ssl_dir}/*.pem
chmod 600 ${etcd_ssl_dir}/etcd.key

for i in etcd2 flanneld kube-apiserver kube-controller-manager; do
  sudo systemctl restart $i.service
done
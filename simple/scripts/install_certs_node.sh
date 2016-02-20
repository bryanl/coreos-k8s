#!/usr/bin/env bash

set -e

etcd_ssl_dir=/etc/ssl/etcd
mkdir -p $etcd_ssl_dir

# copy key and certs to their proper place
for i in ca.pem client.pem client.key; do
  mv /home/core/$i ${etcd_ssl_dir}/$i
done

chown etcd:wheel ${etcd_ssl_dir}/*
chmod 644 ${etcd_ssl_dir}/*.pem
chmod 644 ${etcd_ssl_dir}/client.key

for i in fleet flanneld; do
  sudo systemctl restart $i.service
done



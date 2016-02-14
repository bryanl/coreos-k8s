#!/usr/bin/env bash

set -e

etcd_ssl_dir=/etc/ssl/etcd
mkdir -p $etcd_ssl_dir

# copy key and certs to their proper place
mv /home/core/ca.pem ${etcd_ssl_dir}/ca.pem
mv /home/core/etcd.pem ${etcd_ssl_dir}/etcd.pem
mv /home/core/etcd.key ${etcd_ssl_dir}/etcd.key
chown etcd:wheel ${etcd_ssl_dir}/*
chmod 644 ${etcd_ssl_dir}/*.pem
chmod 600 ${etcd_ssl_dir}/*.key

systemctl restart etcd2.service

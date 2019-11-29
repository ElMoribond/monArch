#!/bin/bash

pacman -S docker docker-compose

mkdir /etc/docker
cat <<EOF >> /etc/docker/daemon.json
{
  "debug": false,
  "log-driver": "journald",
  "dns": ["10.0.0.1", "192.168.1.1"],
  "iptables": false
}
EOF

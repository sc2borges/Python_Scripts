#!/bin/bash

set -e

NODE_VERSION="1.0.1"
NODE_DIR="/opt/prometheus/exporters/dist"
NODE_FOLDER="node_exporter-${NODE_VERSION}.linux-amd64"
NODE_ARCHIVE="${NODE_FOLDER}.tar.gz"

# Install Prometheus Node Eporter

cd $NODE_DIR
wget "https://github.com/prometheus/node_exporter/releases/download/v${NODE_VERSION}/${NODE_ARCHIVE}" -O ${NODE_ARCHIVE}

tar -xzf ${NODE_ARCHIVE}

cd ..
rm node_exporter_current
ln -s $NODE_DIR/$NODE_FOLDER node_exporter_current

#restart the Node Exporter Service
systemctl restart prometheus-node-exporter.service

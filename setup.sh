#!/bin/bash

# Create necessary directories
mkdir -p prometheus
mkdir -p grafana/provisioning/datasources
mkdir -p loki
mkdir -p otel-collector

# Ensure prometheus.yml exists
if [ ! -f prometheus/prometheus.yml ]; then
    cat > prometheus/prometheus.yml <<EOL
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'otel-collector'
    static_configs:
      - targets: ['otel-collector:8889']

  - job_name: 'grafana'
    static_configs:
      - targets: ['grafana:3000']
EOL
fi

# Make sure files have proper permissions
chmod -R 755 prometheus
chmod -R 755 grafana
chmod -R 755 loki
chmod -R 755 otel-collector

echo "Directory structure and configuration files are ready!"

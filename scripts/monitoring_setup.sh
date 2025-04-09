#!/bin/bash
# scripts/monitoring_setup.sh
# Update system packages
sudo apt update
sudo apt upgrade -y

# Install necessary packages
sudo apt install -y wget git unzip

# Create directories for Prometheus and Grafana
sudo mkdir -p /opt/prometheus /opt/grafana /etc/prometheus

# Download and install Prometheus
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.37.0/prometheus-2.37.0.linux-amd64.tar.gz
tar -xvf prometheus-2.37.0.linux-amd64.tar.gz
sudo cp prometheus-2.37.0.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-2.37.0.linux-amd64/promtool /usr/local/bin/
sudo cp -r prometheus-2.37.0.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-2.37.0.linux-amd64/console_libraries /etc/prometheus
rm -rf prometheus-2.37.0.linux-amd64*

# Create Prometheus configuration
cat > /tmp/prometheus.yml << 'EOL'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'application_server'
    static_configs:
      - targets: ['${app_server_ip}:5000']
EOL

# Replace application server IP
sed -i "s/\${app_server_ip}/$(cat /home/ubuntu/app_server_ip.txt || echo "${app_server_ip}")/g" /tmp/prometheus.yml
sudo cp /tmp/prometheus.yml /etc/prometheus/prometheus.yml

# Create Prometheus service
cat > /tmp/prometheus.service << 'EOL'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/opt/prometheus \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOL

sudo cp /tmp/prometheus.service /etc/systemd/system/prometheus.service

# Download and install Grafana
cd /tmp
wget https://dl.grafana.com/oss/release/grafana-9.0.5.linux-amd64.tar.gz
tar -zxvf grafana-9.0.5.linux-amd64.tar.gz
sudo mv grafana-9.0.5 /opt/grafana
rm grafana-9.0.5.linux-amd64.tar.gz

# Create Grafana service
cat > /tmp/grafana.service << 'EOL'
[Unit]
Description=Grafana
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/opt/grafana/bin/grafana-server \
  --config=/opt/grafana/conf/defaults.ini \
  --homepath=/opt/grafana

[Install]
WantedBy=multi-user.target
EOL

sudo cp /tmp/grafana.service /etc/systemd/system/grafana.service

# Start services
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus
sudo systemctl enable grafana
sudo systemctl start grafana

# Create a simple Node Exporter installation script for the application server
cat > /tmp/node_exporter_install.sh << 'EOL'
#!/bin/bash
# This script installs Node Exporter on the application server

# Update package lists
sudo apt update

# Download and install Node Exporter
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz
tar -xvf node_exporter-1.3.1.linux-amd64.tar.gz
sudo cp node_exporter-1.3.1.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-1.3.1.linux-amd64*

# Create Node Exporter service
cat > /tmp/node_exporter.service << 'INNEREOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
INNEREOF

sudo cp /tmp/node_exporter.service /etc/systemd/system/node_exporter.service

# Start Node Exporter service
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
EOL

chmod +x /tmp/node_exporter_install.sh

# Save this script to send to the application server later
cp /tmp/node_exporter_install.sh /home/ubuntu/node_exporter_install.sh

echo "Monitoring server setup completed"
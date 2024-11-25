#!/bin/bash

echo "Configuring Kibana for Wine Blockchain..."

# Create Kibana configuration
sudo tee /etc/kibana/kibana.yml > /dev/null << EOF
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:9200"]
EOF

# Restart Kibana
sudo systemctl restart kibana
sleep 10

echo "Waiting for Kibana to start..."
until curl -s http://localhost:5601 >/dev/null; do
    sleep 1
done

echo "Kibana configuration complete! 🎉"
echo "Access Kibana at http://localhost:5601"

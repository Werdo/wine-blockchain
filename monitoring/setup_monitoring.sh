#!/bin/bash

# Enable error handling
set -e
set -x

# Variables
NODE_IP="167.235.79.28"
ES_VERSION="8.11.1"
KIBANA_VERSION="8.11.1"
ES_PORT="9201"  # Changed from 9200
KIBANA_PORT="5602"  # Changed from 5601
LOGSTASH_PORT="8080"

echo "Starting setup..."

# Clean up any existing installations
cleanup() {
    echo "Cleaning up existing installations..."
    sudo systemctl stop elasticsearch kibana logstash || true
    sudo systemctl disable elasticsearch kibana logstash || true
    sudo rm -f /etc/apt/sources.list.d/elastic-*.list
    sudo apt-key del D88E42B4 || true
    docker-compose down || true
}

cleanup

# Setup repositories properly
echo "Setting up Elastic repository..."
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# Update and install dependencies
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    python3-pip \
    docker.io \
    docker-compose \
    ufw

# Install Python dependencies
pip3 install requests

# Create docker-compose.yml
cat > docker-compose.yml << EOF
version: '3'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:${ES_VERSION}
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=true
      - ELASTIC_PASSWORD=wineBlockchain2024
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - bootstrap.memory_lock=true
    ulimits:
      memlock:
        soft: -1
        hard: -1
    ports:
      - ${ES_PORT}:9200
    volumes:
      - es_data:/usr/share/elasticsearch/data
    networks:
      - elastic
    healthcheck:
      test: ["CMD-SHELL", "curl -s http://localhost:9200"]
      interval: 30s
      timeout: 10s
      retries: 3

  kibana:
    image: docker.elastic.co/kibana/kibana:${KIBANA_VERSION}
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
      - ELASTICSEARCH_USERNAME=elastic
      - ELASTICSEARCH_PASSWORD=wineBlockchain2024
      - SERVER_HOST=0.0.0.0
      - SERVER_PUBLICBASEURL=http://${NODE_IP}:${KIBANA_PORT}
    ports:
      - ${KIBANA_PORT}:5601
    depends_on:
      elasticsearch:
        condition: service_healthy
    networks:
      - elastic
      
  logstash:
    image: docker.elastic.co/logstash/logstash:${ES_VERSION}
    environment:
      - ELASTICSEARCH_USERNAME=elastic
      - ELASTICSEARCH_PASSWORD=wineBlockchain2024
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    ports:
      - "${LOGSTASH_PORT}:8080"
    depends_on:
      elasticsearch:
        condition: service_healthy
    networks:
      - elastic

volumes:
  es_data:
    driver: local

networks:
  elastic:
    driver: bridge
EOF

# Create Logstash configuration
cat > logstash.conf << EOF
input {
  http {
    port => 8080
    codec => json
    host => "0.0.0.0"
  }
}

filter {
  if [type] == "block" {
    mutate {
      add_field => {
        "block_num" => "%{[block_header][block_num]}"
        "timestamp" => "%{[block_header][timestamp]}"
        "producer" => "%{[block_header][producer]}"
      }
    }
  }
  
  if [type] == "transaction" {
    mutate {
      add_field => {
        "tx_id" => "%{[trx][id]}"
        "block_num" => "%{[block_num]}"
        "timestamp" => "%{[timestamp]}"
      }
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    user => "elastic"
    password => "wineBlockchain2024"
    index => "wine-blockchain-%{type}-%{+YYYY.MM.dd}"
  }
}
EOF

# Create blockchain data collector script
cat > collect_blockchain_data.py << EOF
import requests
import json
import time
from datetime import datetime

CHAIN_API = f"http://{NODE_IP}:8888"
LOGSTASH_URL = f"http://localhost:{LOGSTASH_PORT}"

def get_info():
    return requests.get(f"{CHAIN_API}/v1/chain/get_info").json()

def get_block(block_num):
    data = {"block_num_or_id": str(block_num)}
    return requests.post(f"{CHAIN_API}/v1/chain/get_block", json=data).json()

def send_to_logstash(data, doc_type):
    data['type'] = doc_type
    requests.post(LOGSTASH_URL, json=data)

def main():
    last_block = 0
    while True:
        try:
            info = get_info()
            head_block = info['head_block_num']
            
            for block_num in range(last_block + 1, head_block + 1):
                block = get_block(block_num)
                send_to_logstash(block, 'block')
                
                for tx in block.get('transactions', []):
                    if 'trx' in tx and isinstance(tx['trx'], dict):
                        tx_data = {
                            'block_num': block_num,
                            'timestamp': block['timestamp'],
                            'trx': tx['trx']
                        }
                        send_to_logstash(tx_data, 'transaction')
            
            last_block = head_block
            
        except Exception as e:
            print(f"Error: {e}")
            
        time.sleep(0.5)

if __name__ == "__main__":
    main()
EOF

# Configure and start services
echo "Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow ${ES_PORT}/tcp
sudo ufw allow ${KIBANA_PORT}/tcp
sudo ufw allow ${LOGSTASH_PORT}/tcp
sudo ufw --force enable

echo "Starting Docker services..."
sudo systemctl start docker
sudo systemctl enable docker

# Check for running services on ports
check_port() {
    if sudo lsof -i :$1; then
        echo "Port $1 is in use. Stopping service..."
        sudo fuser -k $1/tcp || true
    fi
}

check_port ${ES_PORT}
check_port ${KIBANA_PORT}
check_port ${LOGSTASH_PORT}

# Start containers
echo "Starting containers..."
docker-compose down || true
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 30

# Start data collector
echo "Starting blockchain data collector..."
python3 collect_blockchain_data.py &

echo "=== Setup Complete ==="
echo "Access Details:"
echo "Kibana: http://${NODE_IP}:${KIBANA_PORT}"
echo "Elasticsearch: http://${NODE_IP}:${ES_PORT}"
echo "Logstash: http://${NODE_IP}:${LOGSTASH_PORT}"
echo "Username: elastic"
echo "Password: wineBlockchain2024"

# Create verification script
cat > verify_setup.sh << EOF
#!/bin/bash
echo "Checking Docker containers..."
docker ps

echo "Checking Elasticsearch..."
curl -u elastic:wineBlockchain2024 http://localhost:${ES_PORT}

echo "Checking Kibana..."
curl http://localhost:${KIBANA_PORT}

echo "Checking Logstash..."
curl http://localhost:${LOGSTASH_PORT}
EOF

chmod +x verify_setup.sh

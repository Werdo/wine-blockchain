#!/bin/bash

echo "Configuring Elasticsearch for Wine Blockchain..."

# Create Elasticsearch configuration
sudo tee /etc/elasticsearch/elasticsearch.yml > /dev/null << EOF
cluster.name: wine-blockchain
node.name: \${HOSTNAME}
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 0.0.0.0
discovery.type: single-node
xpack.security.enabled: true
EOF

# Restart Elasticsearch
sudo systemctl restart elasticsearch
sleep 10

# Wait for Elasticsearch to start
echo "Waiting for Elasticsearch to start..."
until curl -s http://localhost:9200 >/dev/null; do
    sleep 1
done

# Create index template for blockchain data
curl -X PUT "localhost:9200/_template/wine_blockchain" -H 'Content-Type: application/json' -d'
{
  "index_patterns": ["wine-blockchain-*"],
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  },
  "mappings": {
    "properties": {
      "block_num": { "type": "long" },
      "block_time": { "type": "date" },
      "block_producer": { "type": "keyword" },
      "transaction_id": { "type": "keyword" },
      "action_name": { "type": "keyword" },
      "bottle_id": { "type": "keyword" },
      "owner": { "type": "keyword" },
      "metadata": { "type": "object" }
    }
  }
}'

echo "Elasticsearch configuration complete! 🎉"

#!/bin/bash

# Esperar a que Elasticsearch esté disponible
until curl -s http://localhost:9200 >/dev/null; do
    echo "Esperando a Elasticsearch..."
    sleep 5
done

# Crear template para índices de blockchain
curl -X PUT "localhost:9200/_template/wine_blockchain" -H 'Content-Type: application/json' -d'
{
  "index_patterns": ["wine-blockchain-*"],
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 1,
    "index.lifecycle.name": "wine_blockchain_policy",
    "index.lifecycle.rollover_alias": "wine-blockchain"
  },
  "mappings": {
    "properties": {
      "timestamp": {
        "type": "date"
      },
      "transaction_type": {
        "type": "keyword"
      },
      "bottle_id": {
        "type": "keyword"
      },
      "actor": {
        "type": "keyword"
      },
      "action": {
        "type": "keyword"
      },
      "data": {
        "type": "object",
        "dynamic": true
      }
    }
  }
}'

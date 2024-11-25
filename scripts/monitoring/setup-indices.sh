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

# Crear política de ciclo de vida
curl -X PUT "localhost:9200/_ilm/policy/wine_blockchain_policy" -H 'Content-Type: application/json' -d'
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_size": "50GB",
            "max_age": "30d"
          },
          "set_priority": {
            "priority": 100
          }
        }
      },
      "warm": {
        "min_age": "30d",
        "actions": {
          "shrink": {
            "number_of_shards": 1
          },
          "forcemerge": {
            "max_num_segments": 1
          },
          "set_priority": {
            "priority": 50
          }
        }
      },
      "cold": {
        "min_age": "60d",
        "actions": {
          "set_priority": {
            "priority": 0
          }
        }
      },
      "delete": {
        "min_age": "90d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}'

# Crear dashboard inicial en Kibana
curl -X POST "localhost:5601/api/saved_objects/dashboard/wine-blockchain" -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d'
{
  "attributes": {
    "title": "Wine Blockchain Overview",
    "hits": 0,
    "description": "Overview of wine blockchain transactions and bottle tokens",
    "panelsJSON": "[]",
    "optionsJSON": "{\"darkTheme\":false,\"useMargins\":true,\"hidePanelTitles\":false}",
    "version": 1,
    "timeRestore": false,
    "kibanaSavedObjectMeta": {
      "searchSourceJSON": "{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[]}"
    }
  }
}'

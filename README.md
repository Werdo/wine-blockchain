# Wine Blockchain Platform

EOS-based blockchain implementation for the wine industry, enabling bottle tokenization and traceability.

## Features

- Custom EOS blockchain implementation
- Bottle tokenization smart contracts
- Microcontroller node support
- Elasticsearch monitoring integration
- Automated deployment scripts

## Setup

1. Install dependencies:
```bash
./scripts/install-dependencies.sh
```

2. Configure nodes:
```bash
./scripts/setup-node.sh <node-name>
```

3. Setup monitoring:
```bash
./scripts/monitoring/setup-elasticsearch.sh
./scripts/monitoring/setup-kibana.sh
```

## Architecture

The platform consists of:
- EOS blockchain nodes
- Microcontroller nodes (ESP32/Raspberry Pi)
- Elasticsearch/Kibana monitoring
- Smart contracts for bottle tokenization

## Documentation

See the `/docs` directory for detailed documentation.


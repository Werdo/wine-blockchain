# Wine Blockchain Platform

EOS-based blockchain implementation for the wine industry, enabling bottle tokenization and traceability.

## Features

- Custom EOS blockchain implementation
- Bottle tokenization smart contracts
- Microcontroller node support
- Elasticsearch monitoring integration
- Automated deployment scripts

## Setup
Para usar estos scripts:

1. Crea los directorios necesarios:
```bash
mkdir -p ~/wine-blockchain/scripts/monitoring
```

2. Copia cada script en su ubicación correspondiente y hazlos ejecutables:
```bash
chmod +x set-permissions.sh
./set-permissions.sh
chmod +x ~/wine-blockchain/scripts/*.sh
chmod +x ~/wine-blockchain/scripts/monitoring/*.sh
```
3. Install dependencies:
```bash
./scripts/install-dependencies.sh
```

4. Configure nodes:
```bash
./scripts/setup-node.sh <node-name>
```

5. Setup monitoring:
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


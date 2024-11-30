#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuración del nodo génesis
GENESIS_IP="167.235.79.28"
GENESIS_P2P_PORT=9876
GENESIS_HTTP_PORT=8888
CHAIN_ID="wine$(date +%s)"
NODE_TYPE=""

# Directorios
CONFIG_DIR="$HOME/wine-blockchain/config"
GENESIS_DIR="$HOME/wine-blockchain/genesis"
NODES_DIR="$HOME/wine-blockchain/nodes"

# Crear directorios necesarios
mkdir -p $CONFIG_DIR $GENESIS_DIR $NODES_DIR

# Función para generar claves EOS
generate_key_pair() {
    cleos create key --to-console | tail -n 2 | awk '{print $3}'
}

# Cleanup
cleanup() {
    pkill nodeos 2>/dev/null || true
    sleep 2
    rm -rf $NODES_DIR/genesis/data/*
}

# Configuración del nodo génesis
setup_genesis_node() {
    local node_dir="$NODES_DIR/genesis"
    mkdir -p $node_dir/{config,data}

    # Generar par de claves para el productor
    local priv_key=$(generate_key_pair | head -n 1)
    local pub_key=$(generate_key_pair | tail -n 1)

    # Crear config.ini para nodo génesis
    cat > $node_dir/config/config.ini << EOF
chain-state-db-size-mb = 8192
reversible-blocks-db-size-mb = 340
contracts-console = true
verbose-http-errors = true
abi-serializer-max-time-ms = 2000
max-transaction-time = 1000

http-server-address = 0.0.0.0:$GENESIS_HTTP_PORT
p2p-listen-endpoint = 0.0.0.0:$GENESIS_P2P_PORT

plugin = eosio::producer_plugin
plugin = eosio::producer_api_plugin
plugin = eosio::chain_api_plugin
plugin = eosio::http_plugin
plugin = eosio::net_plugin
plugin = eosio::net_api_plugin

producer-name = genesis
signature-provider = $pub_key=KEY:$priv_key

p2p-accept-transactions = true
allowed-connection = any
max-clients = 100
connection-cleanup-period = 30
sync-fetch-span = 100
enable-stale-production = true
pause-on-startup = false
EOF

    # Crear genesis.json
    cat > $GENESIS_DIR/genesis.json << EOF
{
    "initial_timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%S.000')",
    "initial_key": "$pub_key",
    "initial_configuration": {
        "max_block_net_usage": 1048576,
        "target_block_net_usage_pct": 1000,
        "max_transaction_net_usage": 524288,
        "base_per_transaction_net_usage": 12,
        "net_usage_leeway": 500,
        "context_free_discount_net_usage_num": 20,
        "context_free_discount_net_usage_den": 100,
        "max_block_cpu_usage": 200000,
        "target_block_cpu_usage_pct": 1000,
        "max_transaction_cpu_usage": 150000,
        "min_transaction_cpu_usage": 100,
        "max_transaction_lifetime": 3600,
        "deferred_trx_expiration_window": 600,
        "max_transaction_delay": 3888000,
        "max_inline_action_size": 4096,
        "max_inline_action_depth": 4,
        "max_authority_depth": 6
    }
}
EOF

    # Guardar información de claves
    echo "Genesis Node" > $CONFIG_DIR/genesis_keys.txt
    echo "Public Key: $pub_key" >> $CONFIG_DIR/genesis_keys.txt
    echo "Private Key: $priv_key" >> $CONFIG_DIR/genesis_keys.txt
    echo "Chain ID: $CHAIN_ID" >> $CONFIG_DIR/genesis_keys.txt

    echo -e "${GREEN}Nodo génesis configurado${NC}"
    return 0
}

# Configuración de nodo peer
setup_peer_node() {
    local node_name=$1
    local http_port=$2
    local p2p_port=$3
    local node_dir="$NODES_DIR/$node_name"
    
    mkdir -p $node_dir/{config,data}

    # Generar par de claves para el productor
    local priv_key=$(generate_key_pair | head -n 1)
    local pub_key=$(generate_key_pair | tail -n 1)

    # Crear config.ini para nodo peer
    cat > $node_dir/config/config.ini << EOF
chain-state-db-size-mb = 8192
reversible-blocks-db-size-mb = 340
contracts-console = true
verbose-http-errors = true
abi-serializer-max-time-ms = 2000
max-transaction-time = 1000

http-server-address = 0.0.0.0:$http_port
p2p-listen-endpoint = 0.0.0.0:$p2p_port

plugin = eosio::producer_plugin
plugin = eosio::producer_api_plugin
plugin = eosio::chain_api_plugin
plugin = eosio::http_plugin
plugin = eosio::net_plugin
plugin = eosio::net_api_plugin

p2p-peer-address = $GENESIS_IP:$GENESIS_P2P_PORT

producer-name = $node_name
signature-provider = $pub_key=KEY:$priv_key
EOF

    echo "Node: $node_name" >> $CONFIG_DIR/peer_keys.txt
    echo "Public Key: $pub_key" >> $CONFIG_DIR/peer_keys.txt
    echo "Private Key: $priv_key" >> $CONFIG_DIR/peer_keys.txt
    echo "-------------------" >> $CONFIG_DIR/peer_keys.txt

    echo -e "${GREEN}Nodo peer $node_name configurado${NC}"
    return 0
}

# Función para iniciar nodo
start_node() {
    local node_name=$1
    local node_dir="$NODES_DIR/$node_name"
    
    echo -e "${YELLOW}Iniciando nodo $node_name...${NC}"
    
    if [ "$node_name" = "genesis" ]; then
        nodeos \
            --config-dir $node_dir/config \
            --data-dir $node_dir/data \
            --genesis-json $GENESIS_DIR/genesis.json \
            --disable-replay-opts \
            --delete-all-blocks \
            >> $node_dir/nodeos.log 2>&1 &
    else
        nodeos \
            --config-dir $node_dir/config \
            --data-dir $node_dir/data \
            --genesis-json $GENESIS_DIR/genesis.json \
            >> $node_dir/nodeos.log 2>&1 &
    fi
    
    sleep 5
    
    if pgrep -x "nodeos" > /dev/null; then
        echo -e "${GREEN}Nodo $node_name iniciado correctamente${NC}"
        tail -n 50 $node_dir/nodeos.log
    else
        echo -e "${RED}Error al iniciar nodo $node_name${NC}"
        echo "Últimas líneas del log:"
        tail -n 50 $node_dir/nodeos.log
        exit 1
    fi
}

# Script principal
echo -e "${YELLOW}=== Configuración de Red Blockchain EOS ===${NC}"

# Determinar tipo de nodo
read -p "¿Es este el nodo génesis? (s/n): " IS_GENESIS
if [[ $IS_GENESIS =~ ^[Ss]$ ]]; then
    NODE_TYPE="genesis"
    cleanup
    setup_genesis_node
    start_node "genesis"
    
    echo -e "${GREEN}=== Nodo Génesis Iniciado ===${NC}"
    echo "IP: $GENESIS_IP"
    echo "P2P Port: $GENESIS_P2P_PORT"
    echo "HTTP Port: $GENESIS_HTTP_PORT"
    echo "Chain ID: $CHAIN_ID"
    echo "Claves guardadas en: $CONFIG_DIR/genesis_keys.txt"
else
    NODE_TYPE="peer"
    read -p "Nombre del nodo peer: " PEER_NAME
    read -p "Puerto HTTP para este nodo: " PEER_HTTP_PORT
    read -p "Puerto P2P para este nodo: " PEER_P2P_PORT
    
    setup_peer_node $PEER_NAME $PEER_HTTP_PORT $PEER_P2P_PORT
    start_node $PEER_NAME
    
    echo -e "${GREEN}=== Nodo Peer Iniciado ===${NC}"
    echo "Nombre: $PEER_NAME"
    echo "Conectado a: $GENESIS_IP:$GENESIS_P2P_PORT"
    echo "Claves guardadas en: $CONFIG_DIR/peer_keys.txt"
fi

# Crear script de verificación de conexiones
cat > $CONFIG_DIR/check_node.sh << EOF
#!/bin/bash
echo "=== Verificando estado del nodo ==="
curl -s http://localhost:${GENESIS_HTTP_PORT}/v1/chain/get_info | jq
echo
curl -s http://localhost:${GENESIS_HTTP_PORT}/v1/net/connections | jq
EOF

chmod +x $CONFIG_DIR/check_node.sh

echo -e "${GREEN}Script de verificación creado: $CONFIG_DIR/check_node.sh${NC}"

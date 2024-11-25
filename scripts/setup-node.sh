#!/bin/bash

# Check if node name was provided
if [ $# -eq 0 ]; then
    echo "Error: Node name not provided"
    echo "Usage: $0 <node-name>"
    exit 1
fi

NODE_NAME=$1
NODE_DIR="$HOME/wine-blockchain/nodes/$NODE_NAME"
CONFIG_DIR="$HOME/wine-blockchain/config"

echo "Setting up EOS node: $NODE_NAME"

# Create directories
mkdir -p "$NODE_DIR"/{config,data}
mkdir -p "$CONFIG_DIR"

# Generate node configuration
cat > "$NODE_DIR/config/config.ini" << EOF
# EOS Node Configuration for $NODE_NAME
chain-state-db-size-mb = 8192
reversible-blocks-db-size-mb = 340
contracts-console = true
verbose-http-errors = true
abi-serializer-max-time-ms = 2000
enable-stale-production = false
max-transaction-time = 100

# HTTP and P2P Endpoints
http-server-address = 0.0.0.0:8888
p2p-listen-endpoint = 0.0.0.0:9876

# Plugins
plugin = eosio::chain_plugin
plugin = eosio::chain_api_plugin
plugin = eosio::http_plugin
plugin = eosio::history_plugin
plugin = eosio::history_api_plugin
plugin = eosio::net_plugin
plugin = eosio::net_api_plugin

# P2P Peers
p2p-peer-address = localhost:9876
p2p-peer-address = localhost:9877
EOF

# Create genesis.json if it doesn't exist
if [ ! -f "$CONFIG_DIR/genesis.json" ]; then
    cat > "$CONFIG_DIR/genesis.json" << EOF
{
    "initial_timestamp": "2024-03-25T00:00:00.000",
    "initial_key": "EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV",
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
fi

# Start nodeos
echo "Starting nodeos..."
nodeos \
    --config-dir "$NODE_DIR/config" \
    --data-dir "$NODE_DIR/data" \
    --genesis-json "$CONFIG_DIR/genesis.json" \
    >> "$NODE_DIR/nodeos.log" 2>&1 &

# Check if nodeos is running
sleep 5
if pgrep -x "nodeos" > /dev/null; then
    echo "Node started successfully! 🚀"
    echo "Log file: $NODE_DIR/nodeos.log"
else
    echo "Failed to start nodeos. Check logs at: $NODE_DIR/nodeos.log"
    exit 1
fi

#!/bin/bash
# scripts/compile-contracts.sh

# Set working directory
CONTRACT_DIR="smart-contracts/bottle-token"

# Compile the contract
echo "Compiling bottle token contract..."
eosio-cpp -abigen -I $CONTRACT_DIR/include -R $CONTRACT_DIR/ricardian -contract bottle -o $CONTRACT_DIR/bottle.wasm $CONTRACT_DIR/bottle.cpp

if [ $? -eq 0 ]; then
    echo "Contract compiled successfully!"
else
    echo "Error compiling contract"
    exit 1
fi

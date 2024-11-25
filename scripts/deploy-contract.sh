#!/bin/bash
# scripts/deploy-contract.sh

# Set variables
CONTRACT_ACCOUNT="bottletoken"
CONTRACT_DIR="smart-contracts/bottle-token"

# Create account for contract
cleos create account eosio $CONTRACT_ACCOUNT EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV

# Deploy contract
cleos set contract $CONTRACT_ACCOUNT $CONTRACT_DIR bottle.wasm bottle.abi -p $CONTRACT_ACCOUNT@active

echo "Contract deployed to $CONTRACT_ACCOUNT"

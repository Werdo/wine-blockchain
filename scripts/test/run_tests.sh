#!/bin/bash

# Configuración
CONTRACTS_DIR="smart-contracts"
TEST_LOGS_DIR="test-logs"
mkdir -p $TEST_LOGS_DIR

# Iniciar nodeos para testing
nodeos -e -p eosio \
    --plugin eosio::producer_plugin \
    --plugin eosio::chain_api_plugin \
    --plugin eosio::http_plugin \
    --http-server-address=127.0.0.1:8888 \
    --access-control-allow-origin=* \
    --contracts-console \
    --http-validate-host=false \
    --verbose-http-errors \
    --max-transaction-time=100 > $TEST_LOGS_DIR/nodeos.log 2>&1 &

# Esperar a que nodeos esté listo
sleep 2

# Crear cuentas de prueba
cleos create account eosio bottletoken EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cleos create account eosio tester1 EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV
cleos create account eosio tester2 EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV

# Desplegar contrato
cleos set contract bottletoken $CONTRACTS_DIR/bottle-token bottle.wasm bottle.abi

# Ejecutar pruebas
echo "Running contract tests..."

# Test 1: Crear botella
echo "Test 1: Create bottle"
cleos push action bottletoken create '[
  "tester1", 
  {
    "winery": "Test Winery",
    "vintage": "2024",
    "variety": "Test Variety",
    "region": "Test Region",
    "bottle_number": "TEST001",
    "production_date": '$(date +%s)',
    "batch_id": "TEST-BATCH-001"
  }
]' -p tester1@active

# Test 2: Transferir botella
echo "Test 2: Transfer bottle"
cleos push action bottletoken transfer '["tester1", "tester2", 0, "transfer test"]' -p tester1@active

# Test 3: Añadir evento histórico
echo "Test 3: Add history"
cleos push action bottletoken addhistory '[0, "opened", "Bottle opened for testing"]' -p tester2@active

# Verificar resultados
echo "Verifying results..."
cleos get table bottletoken bottletoken bottles
cleos get table bottletoken bottletoken history

# Limpiar
pkill nodeos

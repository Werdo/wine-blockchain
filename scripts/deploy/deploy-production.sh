#!/bin/bash

echo "Deploying to production environment..."

# Verificar rama principal
if [[ $(git rev-parse --abbrev-ref HEAD) != "main" ]]; then
    echo "Error: Must deploy from main branch"
    exit 1
fi

# Actualizar configuración de Kubernetes
kubectl config use-context wine-production

# Aplicar configuraciones
kubectl apply -f k8s/production/namespace.yaml
kubectl apply -f k8s/production/configmap.yaml
kubectl apply -f k8s/production/secrets.yaml

# Desplegar componentes con canary
kubectl apply -f k8s/production/blockchain-nodes-canary.yaml
sleep 30

# Verificar health del canary
if kubectl rollout status deployment/blockchain-node-canary -n wine-blockchain; then
    echo "Canary healthy, proceeding with full deployment"
    kubectl apply -f k8s/production/blockchain-nodes.yaml
    kubectl apply -f k8s/production/monitoring.yaml
    kubectl apply -f k8s/production/ingress.yaml
else
    echo "Canary deployment failed, rolling back"
    kubectl rollout undo deployment/blockchain-node-canary -n wine-blockchain
    exit 1
fi

# Verificar despliegue
kubectl rollout status deployment/blockchain-node -n wine-blockchain
kubectl rollout status deployment/monitoring -n wine-blockchain

echo "Production deployment complete"

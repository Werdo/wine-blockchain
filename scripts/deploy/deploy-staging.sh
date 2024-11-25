#!/bin/bash

echo "Deploying to staging environment..."

# Actualizar configuración de Kubernetes
kubectl config use-context wine-staging

# Aplicar configuraciones
kubectl apply -f k8s/staging/namespace.yaml
kubectl apply -f k8s/staging/configmap.yaml
kubectl apply -f k8s/staging/secrets.yaml

# Desplegar componentes
kubectl apply -f k8s/staging/blockchain-nodes.yaml
kubectl apply -f k8s/staging/monitoring.yaml
kubectl apply -f k8s/staging/ingress.yaml

# Verificar despliegue
kubectl rollout status deployment/blockchain-node -n wine-blockchain
kubectl rollout status deployment/monitoring -n wine-blockchain

echo "Staging deployment complete"

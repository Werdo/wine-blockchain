Para usar este script:

1. En el nodo génesis (168.119.238.152):
```bash
./setup-genesis-node.sh
# Responder 's' cuando pregunte si es nodo génesis
```

2. En cada nodo peer:
```bash
./setup-genesis-node.sh
# Responder 'n' cuando pregunte si es nodo génesis
# Proporcionar nombre del nodo y puertos
```

Para verificar las conexiones:
```bash
./check_node.sh
```

Para detener un nodo:
```bash
pkill nodeos
```

Características principales:

1. **Nodo Génesis**:
   - Se configura como el nodo inicial
   - Acepta conexiones entrantes
   - Mantiene la lista de productores inicial

2. **Nodos Peer**:
   - Se conectan automáticamente al nodo génesis
   - Configurados para sincronizar la cadena
   - Pueden actuar como productores de bloques

3. **Seguridad**:
   - Genera claves únicas para cada nodo
   - Guarda las claves en archivos separados
   - Configura permisos y roles

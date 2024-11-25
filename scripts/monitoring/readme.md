Para implementar este sistema de monitoreo:

1. Crear la estructura de directorios:
```bash
mkdir -p docker/{elasticsearch,kibana,logstash/{config,pipeline}}
```

2. Copiar los archivos de configuración a sus respectivos directorios.

3. Iniciar el stack ELK:
```bash
docker-compose up -d
```

4. Ejecutar el script de configuración de índices:
```bash
./scripts/monitoring/setup-indices.sh
```

5. Iniciar el monitor de transacciones:
```bash
python3 scripts/monitoring/monitor-transactions.py
```

Principales características de esta configuración:

1. **Elasticsearch**:
   - Configurado para almacenar datos de transacciones y tokens
   - Política de retención de datos configurada
   - Índices optimizados para búsqueda

2. **Kibana**:
   - Dashboard predefinido para visualización de datos
   - Monitoreo en tiempo real
   - Capacidades de reportes habilitadas

3. **Logstash**:
   - Pipeline configurado para procesar datos de la blockchain
   - Filtros para enriquecer datos
   - Salida a Elasticsearch con índices dinámicos

4. **Monitor de Transacciones**:
   - Script Python para capturar transacciones
   - Envío de datos a Logstash
   - Manejo de errores y reconexión

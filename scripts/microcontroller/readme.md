Características principales de esta implementación:

1. **Gestión de Eventos:**
   - Almacenamiento circular de eventos
   - Hash encadenado para validación
   - Verificación de integridad de la cadena

2. **Conectividad:**
   - Conexión WiFi
   - Sincronización NTP
   - Comunicación con la blockchain principal

3. **Seguridad:**
   - Generación de ID único por nodo
   - Hashing SHA-256
   - Verificación de integridad

4. **Persistencia:**
   - Almacenamiento en EEPROM
   - Manejo de memoria circular
   - Límite configurable de eventos

Para usar este sistema:

1. **Preparación:**
```bash
# Instalar herramientas
./scripts/microcontroller/setup.sh

# Compilar y subir
./scripts/microcontroller/compile_upload.sh

# Monitorear
./scripts/microcontroller/monitor.sh
```

2. **Comandos de prueba** (vía monitor serial):
```
ADD bottle123 open     # Registrar apertura de botella
ADD bottle123 close    # Registrar cierre de botella
VERIFY                 # Verificar integridad de la cadena
```

3. **Integración con la blockchain principal:**
   - Los eventos se reportan automáticamente
   - Sincronización periódica cada 5 minutos
   - Verificación de integridad continua

#!/bin/bash

# set-permissions.sh

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}==================================================${NC}"
echo -e "${GREEN}     Wine Blockchain Scripts Permission Setup${NC}"
echo -e "${YELLOW}==================================================${NC}"

# Verificar si el directorio existe
if [ ! -d "wine-blockchain" ]; then
    echo -e "${YELLOW}Clonando repositorio...${NC}"
    git clone https://github.com/Werdo/wine-blockchain.git
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: No se pudo clonar el repositorio${NC}"
        exit 1
    fi
fi

cd wine-blockchain

# Array de directorios donde buscar scripts
SCRIPT_DIRS=(
    "scripts"
    "scripts/microcontroller"
    "scripts/monitoring"
    "scripts/deploy"
    "scripts/test"
)

# Contador para scripts encontrados
COUNTER=0

echo -e "${YELLOW}Buscando y estableciendo permisos...${NC}"

# Función para dar permisos a los scripts
set_permissions() {
    local file=$1
    if [[ -f "$file" && ( "$file" == *.sh || "$file" == *.py ) ]]; then
        chmod +x "$file"
        ((COUNTER++))
        echo -e "${GREEN}✔ Permisos establecidos:${NC} $file"
    fi
}

# Recorrer directorios conocidos
for dir in "${SCRIPT_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${YELLOW}Procesando directorio: $dir${NC}"
        # Encontrar todos los archivos .sh y .py en el directorio
        find "$dir" -type f \( -name "*.sh" -o -name "*.py" \) -exec bash -c 'set_permissions "$0"' {} \;
    fi
done

# Búsqueda adicional en todo el repositorio por si hay scripts en otros directorios
echo -e "${YELLOW}Buscando scripts adicionales...${NC}"
find . -type f \( -name "*.sh" -o -name "*.py" \) | while read file; do
    set_permissions "$file"
done

echo -e "${YELLOW}==================================================${NC}"
echo -e "${GREEN}Proceso completado!${NC}"
echo -e "${GREEN}Total de scripts procesados: $COUNTER${NC}"
echo -e "${YELLOW}==================================================${NC}"

# Verificar si hay scripts en el repositorio
if [ $COUNTER -eq 0 ]; then
    echo -e "${RED}Advertencia: No se encontraron scripts en el repositorio${NC}"
    echo -e "${YELLOW}Verifique que el repositorio contiene los archivos esperados${NC}"
else
    echo -e "${GREEN}Todos los scripts tienen ahora permisos de ejecución${NC}"
    echo -e "${YELLOW}Puede ejecutar los scripts con ./<nombre_script>.sh${NC}"
fi

# Listar los scripts encontrados
echo -e "\n${YELLOW}Scripts encontrados y procesados:${NC}"
for dir in "${SCRIPT_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        find "$dir" -type f \( -name "*.sh" -o -name "*.py" \) -ls
    fi
done

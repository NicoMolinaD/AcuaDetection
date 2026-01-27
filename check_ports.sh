#!/bin/bash

# Script de Verificación de Puertos - AcuaDetection
# Verifica que los puertos nuevos estén disponibles antes de iniciar

set -e

echo "===================================================================="
echo "  Verificación de Disponibilidad de Puertos - AcuaDetection"
echo "===================================================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Función para verificar puerto
check_port() {
    local port=$1
    local name=$2
    
    if nc -z 127.0.0.1 $port 2>/dev/null; then
        echo -e "${RED} [FAILED]${NC} Puerto $port ($name) - EN USO"
        return 1
    else
        echo -e "${GREEN}${NC} Puerto $port ($name) - Disponible"
        return 0
    fi
}

# Función para verificar puerto con lsof
check_port_lsof() {
    local port=$1
    local name=$2
    
    if sudo lsof -i :$port >/dev/null 2>&1; then
        echo -e "${RED} [FAILED]${NC} Puerto $port ($name) - EN USO"
        return 1
    else
        echo -e "${GREEN}${NC} Puerto $port ($name) - Disponible"
        return 0
    fi
}

echo " Verificando puertos necesarios para AcuaDetection..."
echo ""

# Array de puertos a verificar
declare -a PORTS=(
    "8080:HTTP (redirect)"
    "8443:HTTPS (TLS)"
    "5434:PostgreSQL"
)

# Variables para tracking
total=0
available=0
conflicts=0

# Verificar cada puerto
for port_info in "${PORTS[@]}"; do
    IFS=':' read -r port name <<< "$port_info"
    total=$((total + 1))
    
    if check_port_lsof $port "$name"; then
        available=$((available + 1))
    else
        conflicts=$((conflicts + 1))
    fi
done

echo ""
echo "===================================================================="
echo "  RESULTADO"
echo "===================================================================="
echo ""

if [ $conflicts -eq 0 ]; then
    echo -e "${GREEN}[OK] ÉXITO: Todos los puertos están disponibles${NC}"
    echo ""
    echo "Información de acceso:"
    echo "  HTTP:       http://aquadetection.local:8080"
    echo "  HTTPS:      https://aquadetection.local:8443"
    echo "  PostgreSQL: 127.0.0.1:5434"
    echo ""
    echo "Puedes ejecutar: ./start.sh"
    exit 0
else
    echo -e "${RED}[FAILED] ERROR: Hay $conflicts puerto(s) en conflicto${NC}"
    echo ""
    echo "Soluciones:"
    echo ""
    
    # Mostrar procesos ocupando los puertos
    for port_info in "${PORTS[@]}"; do
        IFS=':' read -r port name <<< "$port_info"
        if sudo lsof -i :$port >/dev/null 2>&1; then
            echo "Puerto $port ($name):"
            sudo lsof -i :$port | tail -n +2 | awk '{print "  PID: " $2 " - Comando: " $1}'
            echo ""
        fi
    done
    
    echo "Opciones:"
    echo "1. Liberar los puertos conflictivos (matar procesos)"
    echo "2. Cambiar los puertos en docker-compose.yml"
    echo "   Ejemplo: cambiar 8443 a 9443"
    echo ""
    exit 1
fi

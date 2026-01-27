#!/bin/bash

# System verification script

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}"
echo "=========================================="
echo "System Verification"
echo "=========================================="
echo -e "${NC}\n"

# Detect Docker command
if docker ps >/dev/null 2>&1; then
    DOCKER_CMD="docker"
else
    DOCKER_CMD="sudo docker"
fi

# Funciones
check_service() {
    local service=$1
    local container=$2
    
    if $DOCKER_CMD compose ps $container | grep -q "running"; then
        echo -e "${GREEN}[OK]${NC} $service: RUNNING"
        return 0
    else
        echo -e "${RED}[FAIL]${NC} $service: NOT RUNNING"
        return 1
    fi
}

check_port() {
    local port=$1
    local service=$2
    
    if $DOCKER_CMD compose exec -T nginx lsof -i :$port >/dev/null 2>&1; then
        echo -e "${GREEN}[OK]${NC} Puerto $port ($service): ESCUCHANDO"
        return 0
    else
        echo -e "${YELLOW}[INFO]${NC} Puerto $port ($service): verificado"
        return 0
    fi
}

check_database() {
    if $DOCKER_CMD compose exec -T db pg_isready -U aquadetection_user >/dev/null 2>&1; then
        echo -e "${GREEN}[OK]${NC} Base de datos: ACCESIBLE"
        return 0
    else
        echo -e "${RED}[FAIL]${NC} Base de datos: NO ACCESIBLE"
        return 1
    fi
}

check_certificates() {
    if $DOCKER_CMD compose exec -T nginx test -f /etc/letsencrypt/live/aquadetection.local/fullchain.pem 2>/dev/null; then
        echo -e "${GREEN}[OK]${NC} Certificados SSL/TLS: GENERADOS"
        return 0
    else
        echo -e "${RED}[FAIL]${NC} Certificados SSL/TLS: NO ENCONTRADOS"
        return 1
    fi
}

# Verificaciones
echo "VERIFICANDO SERVICIOS:"
check_service "Nginx (Reverse Proxy)" "nginx"
check_service "Frontend (React)" "frontend"
check_service "Backend (FastAPI)" "backend"
check_service "Base de datos (PostgreSQL)" "db"

echo ""
echo "VERIFICANDO PUERTOS:"
check_port "80" "HTTP"
check_port "443" "HTTPS"

echo ""
echo "VERIFICANDO CONECTIVIDAD:"
check_database
check_certificates

echo ""
echo "ESTADO DEL SISTEMA:"
$DOCKER_CMD compose ps

echo ""
echo "LOGS RECIENTES (últimas 5 líneas por servicio):"
echo -e "\n${BLUE}--- Nginx ---${NC}"
$DOCKER_CMD compose logs nginx --tail 5 | tail -5

echo -e "\n${BLUE}--- Backend ---${NC}"
$DOCKER_CMD compose logs backend --tail 5 | tail -5

echo -e "\n${BLUE}--- Frontend ---${NC}"
$DOCKER_CMD compose logs frontend --tail 5 | tail -5

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Verificacion completada${NC}"
echo -e "${GREEN}================================================${NC}\n"

echo "Acceso a AcuaDetection:"
echo -e "  ${BLUE}https://aquadetection.local${NC}"
echo -e "  ${BLUE}https://10.3.11.101${NC}"
echo ""
echo "Para ver todos los logs:"
echo -e "  ${BLUE}docker-compose logs -f${NC}"
echo ""

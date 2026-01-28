#!/bin/bash

set -e

# Códigos de color
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${RED}  Deteniendo AcuaDetection${NC}"
echo -e "${BLUE}================================================${NC}\n"

# Detectar comando docker
if docker ps >/dev/null 2>&1; then
    DOCKER_CMD="docker"
else
    DOCKER_CMD="sudo docker"
fi

# Detener servicios
echo -e "${BLUE}[INFO]${NC} Deteniendo contenedores"
$DOCKER_CMD compose down

if [ $? -eq 0 ]; then
    echo -e "${GREEN}[EXITOSO]${NC} Sistema detenido exitosamente"
    echo -e "\nPara iniciar nuevamente, ejecute: ${BLUE}./start.sh${NC}\n"
else
    echo -e "${RED}[ERROR]${NC} Error al detener el sistema"
    exit 1
fi

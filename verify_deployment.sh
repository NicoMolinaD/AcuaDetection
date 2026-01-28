#!/bin/bash

set -e

# Códigos de color
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "======================================================="
echo "   AcuaDetection - Verificación Previa al Despliegue"
echo "   Red Privada (10.3.11.101:8080/8443)"
echo "======================================================="
echo -e "${NC}"

PASS=0
FAIL=0

echo -e "\n${YELLOW}Verificando archivos requeridos${NC}\n"

# Verificar archivos
FILES=(
    "/home/nicolasmolina-diaz/new/docker-compose.yml:docker-compose.yml"
    "/home/nicolasmolina-diaz/new/start.sh:start.sh"
    "/home/nicolasmolina-diaz/new/backend/init.sql:backend/init.sql"
    "/home/nicolasmolina-diaz/new/infrastructure/nginx/init_certbot.sh:init_certbot.sh"
    "/home/nicolasmolina-diaz/new/infrastructure/nginx/nginx.conf:nginx.conf"
    "/home/nicolasmolina-diaz/new/backend/main.py:backend/main.py"
)

for FILE_PATH in "${FILES[@]}"; do
    FILE="${FILE_PATH%:*}"
    NAME="${FILE_PATH#*:}"
    
    if [ -f "$FILE" ]; then
        echo -e "${GREEN}OK${NC} $NAME"
        ((PASS++))
    else
        echo -e "${RED}FALLO${NC} $NAME (no encontrado)"
        ((FAIL++))
    fi
done

echo -e "\n${YELLOW}Verificando permisos${NC}\n"

if [ -x /home/nicolasmolina-diaz/new/start.sh ]; then
    echo -e "${GREEN}OK${NC} start.sh es ejecutable"
    ((PASS++))
else
    echo -e "${YELLOW}ADVERTENCIA${NC} start.sh no es ejecutable (se puede arreglar)"
    ((PASS++))
fi

echo -e "\n${YELLOW}Verificando sintaxis de scripts${NC}\n"

if bash -n /home/nicolasmolina-diaz/new/start.sh 2>/dev/null; then
    echo -e "${GREEN}OK${NC} start.sh - Sintaxis válida"
    ((PASS++))
else
    echo -e "${RED}FALLO${NC} start.sh - Error de sintaxis"
    ((FAIL++))
fi

if bash -n /home/nicolasmolina-diaz/new/infrastructure/nginx/init_certbot.sh 2>/dev/null; then
    echo -e "${GREEN}OK${NC} init_certbot.sh - Sintaxis válida"
    ((PASS++))
else
    echo -e "${RED}FALLO${NC} init_certbot.sh - Error de sintaxis"
    ((FAIL++))
fi

echo -e "\n${YELLOW}Verificando configuración${NC}\n"

# Verificar puertos en docker-compose.yml
if grep -q "8080:80" /home/nicolasmolina-diaz/new/docker-compose.yml; then
    echo -e "${GREEN}OK${NC} Puerto 8080 configurado en docker-compose.yml"
    ((PASS++))
else
    echo -e "${RED}FALLO${NC} Puerto 8080 NO encontrado en docker-compose.yml"
    ((FAIL++))
fi

if grep -q "8443:443" /home/nicolasmolina-diaz/new/docker-compose.yml; then
    echo -e "${GREEN}OK${NC} Puerto 8443 configurado en docker-compose.yml"
    ((PASS++))
else
    echo -e "${RED}FALLO${NC} Puerto 8443 NO encontrado en docker-compose.yml"
    ((FAIL++))
fi

# Verificar certificados en nginx.conf
if grep -q "/etc/letsencrypt/live/aquadetection-local" /home/nicolasmolina-diaz/new/infrastructure/nginx/nginx.conf; then
    echo -e "${GREEN}OK${NC} Certificados autofirmados configurados en nginx.conf"
    ((PASS++))
else
    echo -e "${RED}FALLO${NC} Certificados NO configurados en nginx.conf"
    ((FAIL++))
fi

# Resumen
echo ""
echo -e "${BLUE}=======================================================${NC}"
echo -e "${BLUE}            RESUMEN DE VERIFICACIÓN${NC}"
echo -e "${BLUE}=======================================================${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}SISTEMA LISTO PARA DESPLEGAR${NC}"
    echo -e "  ${GREEN}OK${NC} $PASS verificaciones exitosas"
    echo ""
    echo -e "${BLUE}Próximos pasos:${NC}"
    echo -e "  1. cd /home/nicolasmolina-diaz/new"
    echo -e "  2. ./start.sh"
    echo ""
    echo -e "${YELLOW}El sistema estará disponible en:${NC}"
    echo -e "  https://10.3.11.101:8443"
    echo -e "  http://10.3.11.101:8080"
    echo ""
    exit 0
else
    echo -e "${RED}RESUELVA LOS PROBLEMAS ANTES DEL DESPLIEGUE${NC}"
    echo -e "  ${GREEN}OK${NC} $PASS verificaciones exitosas"
    echo -e "  ${RED}FALLO${NC} $FAIL verificaciones fallidas"
    exit 1
fi

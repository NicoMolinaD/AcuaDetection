#!/bin/bash

# Script de Validación de Configuración SSL/TLS
# Verifica que todos los componentes estén correctamente configurados

set -e

echo " Validación de Configuración SSL/TLS"
echo "======================================"
echo ""

ERRORES=0
ADVERTENCIAS=0

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

verificacion_exitosa() {
    echo -e "${GREEN}${NC} $1"
}

verificacion_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ((ERRORES++))
}

verificacion_advertencia() {
    echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"
    ((ADVERTENCIAS++))
}

# Verificar archivos
echo "Verificando archivos requeridos"
ARCHIVOS=(
    "docker-compose.yml"
    "infrastructure/nginx/Dockerfile"
    "infrastructure/nginx/nginx.conf"
    "infrastructure/nginx/init_certbot.sh"
    "infrastructure/nginx/renew_certs.sh"
    ".env.example"
    "SSL_TLS_SETUP.md"
    "ARCHITECTURE.md"
    "MIGRATION_NOTES.md"
    "setup_ssl.sh"
)

for archivo in "${ARCHIVOS[@]}"; do
    if [ -f "$archivo" ]; then
        verificacion_exitosa "Archivo: $archivo"
    else
        verificacion_error "Falta archivo: $archivo"
    fi
done

echo ""
echo "Verificando Docker..."

# Verificar Docker
if command -v docker &> /dev/null; then
    verificacion_exitosa "Docker instalado"
    DOCKER_EN_EJECUCION=$(docker ps 2>/dev/null | wc -l)
    if [ "$DOCKER_EN_EJECUCION" -gt 1 ]; then
        verificacion_exitosa "Docker daemon ejecutándose"
    else
        verificacion_advertencia "Docker daemon no está ejecutándose"
    fi
else
    verificacion_error "Docker no instalado"
fi

if command -v docker-compose &> /dev/null; then
    verificacion_exitosa "docker-compose instalado"
else
    verificacion_error "docker-compose no instalado"
fi

echo ""
echo " Verificando configuración..."

# Verificar .env
if [ -f ".env" ]; then
    verificacion_exitosa "Archivo .env existe"
    
    if grep -q "DOMAIN_NAME=aquadetection.local" .env; then
        verificacion_exitosa "DOMAIN_NAME configurado"
    else
        verificacion_advertencia "DOMAIN_NAME no está configurado o es incorrecto"
    fi
    
    if grep -q "EMAIL=" .env; then
        verificacion_exitosa "EMAIL configurado"
    else
        verificacion_advertencia "EMAIL no está configurado"
    fi
    
    if grep -q "ALLOWED_IP=10.3.11.101" .env; then
        verificacion_exitosa "ALLOWED_IP configurado correctamente"
    else
        verificacion_advertencia "ALLOWED_IP no está configurado a 10.3.11.101"
    fi
else
    verificacion_error "Archivo .env no existe (ejecute: cp .env.example .env)"
fi

echo ""
echo " Verificando /etc/hosts..."

# Verificar /etc/hosts
if grep -q "aquadetection.local" /etc/hosts 2>/dev/null; then
    verificacion_exitosa "aquadetection.local en /etc/hosts"
else
    verificacion_advertencia "aquadetection.local NO está en /etc/hosts"
    echo "      Ejecute: sudo nano /etc/hosts"
    echo "      Agregue: 10.3.11.101 aquadetection.local"
fi

echo ""
echo " Verificando docker-compose.yml..."

# Verificar docker-compose.yml
if grep -q "malcom_nginx" docker-compose.yml; then
    verificacion_exitosa "Servicio nginx configurado"
else
    verificacion_error "Servicio nginx NO está configurado"
fi

if grep -q "10.3.11.101:80:80" docker-compose.yml; then
    verificacion_exitosa "Puertos expuestos a IP correcta"
else
    verificacion_advertencia "Puertos no están expuestos a 10.3.11.101"
fi

if grep -q "certbot_data" docker-compose.yml; then
    verificacion_exitosa "Volúmenes para certificados configurados"
else
    verificacion_error "Volúmenes para certificados NO están configurados"
fi

echo ""
echo " Verificando nginx.conf..."

# Verificar nginx.conf
if grep -q "ssl_certificate" infrastructure/nginx/nginx.conf; then
    verificacion_exitosa "SSL configurado en nginx"
else
    verificacion_error "SSL NO está configurado en nginx"
fi

if grep -q "geo \$allowed_ip" infrastructure/nginx/nginx.conf; then
    verificacion_exitosa "Whitelist de IP configurada"
else
    verificacion_error "Whitelist de IP NO está configurada"
fi

if grep -q "malcom.local" infrastructure/nginx/nginx.conf; then
    verificacion_exitosa "Dominio configurado en nginx"
else
    verificacion_advertencia "Dominio no está en nginx.conf"
fi

echo ""
echo "======================================"
echo " Resultado de la Validación"
echo "======================================"

if [ $ERRORES -eq 0 ]; then
    echo -e "${GREEN}[EXITOSO] Configuración válida${NC}"
    if [ $ADVERTENCIAS -gt 0 ]; then
        echo -e "${YELLOW}[ADVERTENCIA]  Hay $ADVERTENCIAS advertencia(s) a revisar${NC}"
    fi
else
    echo -e "${RED}[FALLO] Hay $ERRORES error(es) a corregir${NC}"
fi

echo ""
echo " Próximos pasos:"
echo "   1. Revise cualquier advertencia arriba"
echo "   2. Ejecute: chmod +x setup_ssl.sh malcom_ssl.sh"
echo "   3. Ejecute: ./setup_ssl.sh"
echo "   4. Ejecute: docker-compose up -d"
echo "   5. Espere 15 segundos para certificados"
echo "   6. Acceda a: https://malcom.local"
echo ""

# Retornar código de error si hay errores
[ $ERRORES -eq 0 ] && exit 0 || exit 1

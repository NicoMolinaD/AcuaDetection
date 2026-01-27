#!/bin/bash

#  Script de Validación de Configuración SSL/TLS
# Verifica que todos los componentes estén correctamente configurados

set -e

echo " Validación de Configuración SSL/TLS"
echo "======================================"
echo ""

ERRORS=0
WARNINGS=0

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_success() {
    echo -e "${GREEN}${NC} $1"
}

check_error() {
    echo -e "${RED} [FAILED]${NC} $1"
    ((ERRORS++))
}

check_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# 1. Verificar archivos
echo "📁 Verificando archivos..."
FILES=(
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

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        check_success "Archivo: $file"
    else
        check_error "Falta archivo: $file"
    fi
done

echo ""
echo "🐳 Verificando Docker..."

# 2. Verificar Docker
if command -v docker &> /dev/null; then
    check_success "Docker instalado"
    DOCKER_RUNNING=$(docker ps 2>/dev/null | wc -l)
    if [ "$DOCKER_RUNNING" -gt 1 ]; then
        check_success "Docker daemon ejecutándose"
    else
        check_warning "Docker daemon no está ejecutándose"
    fi
else
    check_error "Docker no instalado"
fi

if command -v docker-compose &> /dev/null; then
    check_success "docker-compose instalado"
else
    check_error "docker-compose no instalado"
fi

echo ""
echo " Verificando configuración..."

# 3. Verificar .env
if [ -f ".env" ]; then
    check_success "Archivo .env existe"
    
    if grep -q "DOMAIN_NAME=aquadetection.local" .env; then
        check_success "DOMAIN_NAME configurado"
    else
        check_warning "DOMAIN_NAME no está configurado o es incorrecto"
    fi
    
    if grep -q "EMAIL=" .env; then
        check_success "EMAIL configurado"
    else
        check_warning "EMAIL no está configurado"
    fi
    
    if grep -q "ALLOWED_IP=10.3.11.101" .env; then
        check_success "ALLOWED_IP configurado correctamente"
    else
        check_warning "ALLOWED_IP no está configurado a 10.3.11.101"
    fi
else
    check_error "Archivo .env no existe (ejecuta: cp .env.example .env)"
fi

echo ""
echo " Verificando /etc/hosts..."

# 4. Verificar /etc/hosts
if grep -q "aquadetection.local" /etc/hosts 2>/dev/null; then
    check_success "aquadetection.local en /etc/hosts"
else
    check_warning "aquadetection.local NO está en /etc/hosts"
    echo "      Ejecuta: sudo nano /etc/hosts"
    echo "      Agrega: 10.3.11.101 aquadetection.local"
fi

echo ""
echo " Verificando docker-compose.yml..."

# 5. Verificar docker-compose.yml
if grep -q "malcom_nginx" docker-compose.yml; then
    check_success "Servicio nginx configurado"
else
    check_error "Servicio nginx NO está configurado"
fi

if grep -q "10.3.11.101:80:80" docker-compose.yml; then
    check_success "Puertos expuestos a IP correcta"
else
    check_warning "Puertos no están expuestos a 10.3.11.101"
fi

if grep -q "certbot_data" docker-compose.yml; then
    check_success "Volúmenes para certificados configurados"
else
    check_error "Volúmenes para certificados NO están configurados"
fi

echo ""
echo " Verificando nginx.conf..."

# 6. Verificar nginx.conf
if grep -q "ssl_certificate" infrastructure/nginx/nginx.conf; then
    check_success "SSL configurado en nginx"
else
    check_error "SSL NO está configurado en nginx"
fi

if grep -q "geo \$allowed_ip" infrastructure/nginx/nginx.conf; then
    check_success "Whitelist de IP configurada"
else
    check_error "Whitelist de IP NO está configurada"
fi

if grep -q "malcom.local" infrastructure/nginx/nginx.conf; then
    check_success "Dominio configurado en nginx"
else
    check_warning "Dominio no está en nginx.conf"
fi

echo ""
echo "======================================"
echo " Resultado de la Validación"
echo "======================================"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}[OK] Configuración válida${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}[WARN]  Hay $WARNINGS advertencia(s) a revisar${NC}"
    fi
else
    echo -e "${RED}[FAILED] Hay $ERRORS error(es) a corregir${NC}"
fi

echo ""
echo " Próximos pasos:"
echo "   1. Revisa cualquier advertencia arriba"
echo "   2. Ejecuta: chmod +x setup_ssl.sh malcom_ssl.sh"
echo "   3. Ejecuta: ./setup_ssl.sh"
echo "   4. Ejecuta: docker-compose up -d"
echo "   5. Espera 15 segundos para certificados"
echo "   6. Accede a: https://malcom.local"
echo ""

# Retornar código de error si hay errores
[ $ERRORS -eq 0 ] && exit 0 || exit 1

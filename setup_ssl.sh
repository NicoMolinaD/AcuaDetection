#!/bin/bash

# Script de configuración rápida para SSL/TLS y dominio personalizado
# Ejecutar: bash setup_ssl.sh

set -e

echo "=========================================="
echo " Configurador de SSL/TLS - AcuaDetection"
echo "=========================================="
echo ""

# Variables
DOMAIN_NAME="aquadetection.local"
ALLOWED_IP="10.3.11.101"
ENV_FILE=".env"

# 1. Crear archivo .env si no existe
if [ ! -f "$ENV_FILE" ]; then
    echo " Creando archivo .env..."
    cp .env.example "$ENV_FILE"
    echo " Archivo .env creado (por favor revisa y completa si es necesario)"
else
    echo " Archivo .env ya existe"
fi

# 2. Verificar que los archivos de nginx están en su lugar
echo ""
echo " Verificando archivos de configuración..."

FILES=(
    "infrastructure/nginx/nginx.conf"
    "infrastructure/nginx/Dockerfile"
    "infrastructure/nginx/init_certbot.sh"
    "infrastructure/nginx/renew_certs.sh"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo " $file"
    else
        echo " [FAILED] Falta: $file"
        exit 1
    fi
done

# 3. Actualizar /etc/hosts (si es posible)
echo ""
echo " Configurando /etc/hosts..."

if grep -q "aquadetection.local" /etc/hosts 2>/dev/null; then
    echo " aquadetection.local ya está en /etc/hosts"
else
    echo "[WARN]  Necesitas agregar manualmente a /etc/hosts:"
    echo "   127.0.0.1       aquadetection.local"
    echo "   10.3.11.101     aquadetection.local"
fi

# 4. Crear directorios de volúmenes
echo ""
echo "📁 Creando directorios necesarios..."
mkdir -p infrastructure/nginx/conf.d
echo " Directorios creados"

# 5. Información de configuración
echo ""
echo "=========================================="
echo "[OK] Configuración completada"
echo "=========================================="
echo ""
echo " Configuración actual:"
echo "   • Dominio: $DOMAIN_NAME"
echo "   • IP permitida: $ALLOWED_IP"
echo "   • Puertos: 80 (HTTP) → 443 (HTTPS)"
echo "   • Certificados: /etc/letsencrypt/live/$DOMAIN_NAME/"
echo ""
echo " Próximos pasos:"
echo "   1. Edita .env si necesitas cambios"
echo "   2. Ejecuta: docker-compose up -d"
echo "   3. Accede a: https://$DOMAIN_NAME"
echo ""
echo "📖 Para más información, lee: SSL_TLS_SETUP.md"
echo "=========================================="

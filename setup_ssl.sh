#!/bin/bash

# Script de configuración rápida para SSL/TLS y dominio personalizado
# Ejecutar: bash setup_ssl.sh

set -e

echo "=========================================="
echo " Configurador de SSL/TLS - AcuaDetection"
echo "=========================================="
echo ""

# Variables
NOMBRE_DOMINIO="aquadetection.local"
IP_PERMITIDA="10.3.11.101"
ARCHIVO_ENV=".env"

# 1. Crear archivo .env si no existe
if [ ! -f "$ARCHIVO_ENV" ]; then
    echo " Creando archivo .env..."
    cp .env.example "$ARCHIVO_ENV"
    echo " Archivo .env creado (revise y complete si es necesario)"
else
    echo " Archivo .env ya existe"
fi

# 2. Verificar que los archivos de nginx están en su lugar
echo ""
echo " Verificando archivos de configuración..."

ARCHIVOS=(
    "infrastructure/nginx/nginx.conf"
    "infrastructure/nginx/Dockerfile"
    "infrastructure/nginx/init_certbot.sh"
    "infrastructure/nginx/renew_certs.sh"
)

for archivo in "${ARCHIVOS[@]}"; do
    if [ -f "$archivo" ]; then
        echo " $archivo"
    else
        echo " [FALLO] Falta: $archivo"
        exit 1
    fi
done

# 3. Actualizar /etc/hosts (si es posible)
echo ""
echo " Configurando /etc/hosts..."

if grep -q "aquadetection.local" /etc/hosts 2>/dev/null; then
    echo " aquadetection.local ya está en /etc/hosts"
else
    echo "[ADVERTENCIA]  Necesita agregar manualmente a /etc/hosts:"
    echo "   127.0.0.1       aquadetection.local"
    echo "   10.3.11.101     aquadetection.local"
fi

# 4. Crear directorios de volúmenes
echo ""
echo "Creando directorios requeridos"
mkdir -p infrastructure/nginx/conf.d
echo " Directorios creados"

# 5. Información de configuración
echo ""
echo "=========================================="
echo "[EXITOSO] Configuración completada"
echo "=========================================="
echo ""
echo " Configuración actual:"
echo "   • Dominio: $NOMBRE_DOMINIO"
echo "   • IP permitida: $IP_PERMITIDA"
echo "   • Puertos: 80 (HTTP) → 443 (HTTPS)"
echo "   • Certificados: /etc/letsencrypt/live/$NOMBRE_DOMINIO/"
echo ""
echo " Próximos pasos:"
echo "   1. Edite .env si necesita cambios"
echo "   2. Ejecute: docker-compose up -d"
echo "   3. Acceda a: https://$NOMBRE_DOMINIO"
echo ""
echo "📖 Para más información, lee: SSL_TLS_SETUP.md"
echo "=========================================="

#!/bin/bash

# CertBot and Nginx initialization

set -e

DOMAIN_NAME="${DOMAIN_NAME:-aquadetection.local}"
EMAIL="${EMAIL:-admin@aquadetection.local}"
CERT_DIR="/etc/letsencrypt/live/${DOMAIN_NAME}"

echo "=========================================="
echo "Inicializando CertBot para ${DOMAIN_NAME}"
echo "=========================================="

# Crear directorios si no existen
mkdir -p /var/www/certbot
mkdir -p /etc/letsencrypt

# Verificar si ya existen certificados
if [ ! -d "$CERT_DIR" ]; then
    echo "No se encontraron certificados existentes..."
    
    # Para desarrollo/pruebas: generar certificado autofirmado
    if [ "${CERT_TYPE:-self-signed}" = "self-signed" ]; then
        echo "Generando certificado autofirmado..."
        mkdir -p "$CERT_DIR"
        
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$CERT_DIR/privkey.pem" \
            -out "$CERT_DIR/fullchain.pem" \
            -subj "/C=ES/ST=State/L=City/O=Organization/CN=${DOMAIN_NAME}"
        
        echo " Certificado autofirmado generado en $CERT_DIR"
    else
        echo "Generando certificado con Let's Encrypt..."
        
        # Crear un archivo de configuración temporal para certbot
        certbot certonly --standalone \
            --non-interactive \
            --agree-tos \
            -d "$DOMAIN_NAME" \
            -m "$EMAIL" \
            --cert-name "$DOMAIN_NAME" \
            --preferred-challenges http || echo "Nota: Let's Encrypt requiere acceso externo. Usando certificado autofirmado."
    fi
else
    echo " Certificados encontrados en $CERT_DIR"
fi

# Verificar que los certificados existan
if [ ! -f "$CERT_DIR/privkey.pem" ] || [ ! -f "$CERT_DIR/fullchain.pem" ]; then
    echo "ERROR: Falta alguno de los certificados necesarios"
    exit 1
fi

echo "=========================================="
echo "Iniciando Nginx..."
echo "=========================================="

# Iniciar nginx
exec nginx -g "daemon off;"

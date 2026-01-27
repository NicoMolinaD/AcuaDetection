#!/bin/bash

# Setup Let's Encrypt para producción
# Uso: ./setup_letsencrypt.sh <dominio> <email>

DOMAIN="${1:-aquadetection.local}"
EMAIL="${2:-admin@aquadetection.local}"
CERT_DIR="/etc/letsencrypt/live/${DOMAIN}"

echo "=========================================="
echo "Configurando Let's Encrypt"
echo "=========================================="
echo "Dominio: $DOMAIN"
echo "Email: $EMAIL"

# Verificar si ya existe certificado
if [ -d "$CERT_DIR" ]; then
    echo "[OK] Certificado encontrado en $CERT_DIR"
    exit 0
fi

echo "[INFO] Descargando certificado desde Let's Encrypt..."

# Crear directorio webroot
mkdir -p /var/www/certbot
mkdir -p /etc/letsencrypt

# Usar certbot para obtener certificado
if command -v certbot &> /dev/null; then
    certbot certonly --webroot \
        -w /var/www/certbot \
        --email "$EMAIL" \
        --agree-tos \
        --non-interactive \
        -d "$DOMAIN" 2>&1 || {
        echo "[WARN] No se pudo obtener certificado de Let's Encrypt"
        echo "[INFO] Generando certificado autofirmado como fallback..."
        
        mkdir -p "$CERT_DIR"
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$CERT_DIR/privkey.pem" \
            -out "$CERT_DIR/fullchain.pem" \
            -subj "/C=ES/ST=ES/L=ES/O=AcuaDetection/CN=$DOMAIN"
        
        echo "[OK] Certificado autofirmado creado"
    }
else
    echo "[WARN] certbot no instalado, generando autofirmado"
    mkdir -p "$CERT_DIR"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERT_DIR/privkey.pem" \
        -out "$CERT_DIR/fullchain.pem" \
        -subj "/C=ES/ST=ES/L=ES/O=AcuaDetection/CN=$DOMAIN"
fi

echo "[OK] Certificado listo"

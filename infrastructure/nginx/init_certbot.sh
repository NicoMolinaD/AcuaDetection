#!/bin/bash

# AcuaDetection - Self-signed certificate generation for private network

SERVER_NAME="${SERVER_NAME:-aquadetection-local}"
CERT_NAME="${CERT_NAME:-aquadetection-local}"
CERT_DIR="/etc/letsencrypt/live/${CERT_NAME}"

echo "=========================================="
echo "AcuaDetection - Certificados Locales"
echo "=========================================="
echo "Servidor: $SERVER_NAME"
echo "Certificado: $CERT_NAME"
echo "Destino: $CERT_DIR"
echo "=========================================="

# Crear directorios
mkdir -p /var/www/certbot /etc/letsencrypt

# Verificar si certificado ya existe
if [ -f "$CERT_DIR/privkey.pem" ] && [ -f "$CERT_DIR/fullchain.pem" ]; then
    echo "[OK] Certificado encontrado"
    echo "[OK] Certificados listos"
    echo "=========================================="
    echo "Iniciando Nginx..."
    exec nginx -g "daemon off;"
fi

# Generar certificado autofirmado
echo "[INFO] Generando certificado autofirmado..."
mkdir -p "$CERT_DIR"

openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout "$CERT_DIR/privkey.pem" \
    -out "$CERT_DIR/fullchain.pem" \
    -subj "/C=ES/ST=Local/L=Local/O=AcuaDetection/CN=$SERVER_NAME" 2>/dev/null

chmod 644 "$CERT_DIR/fullchain.pem"
chmod 644 "$CERT_DIR/privkey.pem"

echo "[OK] Certificado autofirmado generado"
echo "     Válido por: 10 años (3650 días)"
echo "     CN: $SERVER_NAME"

# Update nginx.conf with correct paths
echo "[INFO] Configurando Nginx..."
sed -i "s|/etc/letsencrypt/live/aquadetection-local|/etc/letsencrypt/live/$CERT_NAME|g" /etc/nginx/nginx.conf

echo "[OK] Certificados listos"
echo "=========================================="
echo "Iniciando Nginx..."
exec nginx -g "daemon off;"




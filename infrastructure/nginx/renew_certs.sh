#!/bin/bash

# Script para renovar certificados SSL automáticamente
# Se puede ejecutar periódicamente con cron

DOMAIN_NAME="${DOMAIN_NAME:-malcom.local}"
CERT_DIR="/etc/letsencrypt/live/${DOMAIN_NAME}"
LOG_FILE="/var/log/certbot_renewal.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando renovación de certificados..." >> "$LOG_FILE"

# Verificar si el certificado necesita renovación
if [ -f "$CERT_DIR/fullchain.pem" ]; then
    # Renovar certificado
    certbot renew --quiet >> "$LOG_FILE" 2>&1 || {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Error al renovar certificados" >> "$LOG_FILE"
        exit 1
    }
    
    # Recargar nginx si la renovación fue exitosa
    if nginx -t > /dev/null 2>&1; then
        nginx -s reload
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Certificados renovados y Nginx recargado" >> "$LOG_FILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Error en configuración de Nginx" >> "$LOG_FILE"
        exit 1
    fi
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] No se encontró certificado en $CERT_DIR" >> "$LOG_FILE"
    exit 1
fi

#!/bin/bash

# CertBot and Nginx initialization for production

set -e

DOMAIN_NAME="${DOMAIN_NAME:-aquadetection.local}"
EMAIL="${EMAIL:-admin@aquadetection.local}"
CERT_DIR="/etc/letsencrypt/live/${DOMAIN_NAME}"
ACME_SERVER="${ACME_SERVER:-https://acme-v02.api.letsencrypt.org/directory}"

echo "=========================================="
echo "Inicializando certificados para ${DOMAIN_NAME}"
echo "=========================================="
echo "Email: $EMAIL"
echo "=========================================="

# Crear directorios si no existen
mkdir -p /var/www/certbot
mkdir -p /etc/letsencrypt

# Verificar si ya existen certificados válidos
if [ -d "$CERT_DIR" ] && [ -f "$CERT_DIR/privkey.pem" ] && [ -f "$CERT_DIR/fullchain.pem" ]; then
    echo "[OK] Certificados encontrados en $CERT_DIR"
    CERT_VALID=true
else
    CERT_VALID=false
fi

# Si no hay certificados válidos, intentar obtener de Let's Encrypt
if [ "$CERT_VALID" = "false" ]; then
    echo "[INFO] Intentando obtener certificado de Let's Encrypt..."
    
    # Intentar con webroot (requiere que nginx esté corriendo con certbot-friendly config)
    mkdir -p /var/www/certbot
    
    # Crear configuración temporal de nginx solo para validación ACME
    cat > /etc/nginx/nginx.conf.temp << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events { worker_connections 1024; }

http {
    server {
        listen 80;
        server_name _;
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        location / {
            return 301 https://$host$request_uri;
        }
    }
}
EOF
    
    # Copiar configuración temporal
    cp /etc/nginx/nginx.conf.temp /etc/nginx/nginx.conf
    
    # Iniciar nginx temporalmente para validación
    echo "[INFO] Iniciando nginx para validación ACME..."
    nginx -g "daemon off;" &
    NGINX_PID=$!
    sleep 2
    
    # Intentar obtener certificado
    if certbot certonly --webroot \
        -w /var/www/certbot \
        --non-interactive \
        --agree-tos \
        --email "$EMAIL" \
        -d "$DOMAIN_NAME" \
        --server "$ACME_SERVER" 2>&1 | tee /tmp/certbot.log; then
        echo "[OK] Certificado de Let's Encrypt obtenido exitosamente"
        CERT_VALID=true
    else
        echo "[WARN] No se pudo obtener certificado de Let's Encrypt"
        echo "[INFO] Usando certificado autofirmado como fallback"
        
        # Kill nginx temporal
        kill $NGINX_PID 2>/dev/null || true
        wait $NGINX_PID 2>/dev/null || true
    fi
fi

# Si aún no hay certificado válido, crear autofirmado como fallback
if [ "$CERT_VALID" = "false" ]; then
    echo "[INFO] Generando certificado autofirmado..."
    mkdir -p "$CERT_DIR"
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERT_DIR/privkey.pem" \
        -out "$CERT_DIR/fullchain.pem" \
        -subj "/C=ES/ST=Madrid/L=Madrid/O=AcuaDetection/CN=${DOMAIN_NAME}" 2>&1
    
    echo "[OK] Certificado autofirmado creado"
fi

# Verificar que los certificados existan
if [ ! -f "$CERT_DIR/privkey.pem" ] || [ ! -f "$CERT_DIR/fullchain.pem" ]; then
    echo "[ERROR] No se pudo crear certificado"
    exit 1
fi

# Copiar configuración de nginx definitiva (será reemplazada por volumen)
# Pero asegurar que el dominio sea correcto
if [ ! -f /etc/nginx/nginx.conf ] || grep -q "nginx.conf.temp" /etc/nginx/nginx.conf; then
    echo "[INFO] Usando configuración de nginx del volumen"
fi

echo "=========================================="
echo "[OK] Certificados listos"
echo "=========================================="

# Iniciar nginx en foreground
echo "Iniciando Nginx..."
exec nginx -g "daemon off;"


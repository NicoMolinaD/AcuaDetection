#!/bin/bash

# CertBot and Nginx initialization - Simple and reliable version

DOMAIN_NAME="${DOMAIN_NAME:-aquadetection.local}"
EMAIL="${EMAIL:-admin@example.com}"
CERT_DIR="/etc/letsencrypt/live/${DOMAIN_NAME}"

echo "=========================================="
echo "AcuaDetection - Nginx & Certificates Setup"
echo "=========================================="
echo "Domain: $DOMAIN_NAME"
echo "Email:  $EMAIL"
echo "=========================================="

# Create directories
mkdir -p /var/www/certbot /etc/letsencrypt

# Check if certificates already exist
if [ -f "$CERT_DIR/privkey.pem" ] && [ -f "$CERT_DIR/fullchain.pem" ]; then
    echo "[OK] Certificados encontrados"
else
    # Determine if we should try Let's Encrypt or just use self-signed
    USE_LETSENCRYPT=0
    
    # Check if domain looks like production (not local, not localhost, has TLD)
    if [[ ! "$DOMAIN_NAME" =~ \.local$ ]] && [[ "$DOMAIN_NAME" != "localhost" ]] && [[ "$DOMAIN_NAME" =~ \. ]]; then
        # Check if email looks valid
        if [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            USE_LETSENCRYPT=1
        fi
    fi
    
    if [ $USE_LETSENCRYPT -eq 1 ]; then
        echo "[INFO] Intentando obtener certificado de Let's Encrypt..."
        mkdir -p "$CERT_DIR" /tmp/nginx_acme
        
        # Minimal nginx config for ACME validation
        cat > /tmp/nginx_acme/nginx.conf << 'EOF'
user nginx;
worker_processes 1;
error_log /var/log/nginx/error.log warn;
events { worker_connections 128; }
http {
    server {
        listen 80 default_server;
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
        
        # Start temporary nginx
        nginx -c /tmp/nginx_acme/nginx.conf 2>/dev/null &
        TEMP_NGINX_PID=$!
        sleep 2
        
        # Try to get certificate
        if certbot certonly --webroot -w /var/www/certbot --non-interactive --agree-tos --email "$EMAIL" -d "$DOMAIN_NAME" >/dev/null 2>&1; then
            echo "[OK] ¡Certificado Let's Encrypt obtenido!"
            kill $TEMP_NGINX_PID 2>/dev/null || true
            wait $TEMP_NGINX_PID 2>/dev/null || true
        else
            echo "[WARN] No se pudo obtener Let's Encrypt, usando autofirmado"
            kill $TEMP_NGINX_PID 2>/dev/null || true
            wait $TEMP_NGINX_PID 2>/dev/null || true
            # Fall through to self-signed
        fi
    else
        echo "[INFO] Usando certificado autofirmado"
    fi
    
    # Create self-signed if it doesn't exist
    if [ ! -f "$CERT_DIR/privkey.pem" ] || [ ! -f "$CERT_DIR/fullchain.pem" ]; then
        mkdir -p "$CERT_DIR"
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$CERT_DIR/privkey.pem" \
            -out "$CERT_DIR/fullchain.pem" \
            -subj "/C=ES/ST=Madrid/L=Madrid/O=AcuaDetection/CN=$DOMAIN_NAME" 2>/dev/null
        echo "[OK] Certificado autofirmado creado"
    fi
fi

# Update nginx.conf with the correct domain
echo "[INFO] Configurando Nginx para $DOMAIN_NAME..."
sed -i "s|/etc/letsencrypt/live/aquadetection.local|/etc/letsencrypt/live/$DOMAIN_NAME|g" /etc/nginx/nginx.conf

echo "[OK] Certificados listos"
echo "=========================================="
echo "Iniciando Nginx..."
exec nginx -g "daemon off;"



#!/bin/bash

#  Script de Deployment para Nube
# Facilita la configuración y deployment en AWS, Azure, GCP, etc.

set -e

echo "============================================================"
echo " AcuaDetection Cloud Deployment Setup"
echo "============================================================"
echo ""

# Verificar si estamos en el directorio correcto
if [ ! -f "docker-compose.yml" ]; then
    echo "[FAILED] Error: docker-compose.yml no encontrado"
    echo "Ejecuta este script desde el directorio raíz del proyecto"
    exit 1
fi

# Menú interactivo
echo "Selecciona tu proveedor de nube:"
echo "1) AWS (EC2)"
echo "2) Azure (VM)"
echo "3) Google Cloud (Compute Engine)"
echo "4) Otro (Configuración manual)"
echo ""
read -p "Opción (1-4): " provider_choice

case $provider_choice in
    1)
        echo "📦 Configurando para AWS EC2..."
        provider="AWS EC2"
        firewall_note="AWS Security Group"
        ;;
    2)
        echo "📦 Configurando para Azure VM..."
        provider="Azure VM"
        firewall_note="Azure Network Security Group (NSG)"
        ;;
    3)
        echo "📦 Configurando para Google Cloud..."
        provider="Google Cloud Compute Engine"
        firewall_note="Google Cloud Firewall"
        ;;
    *)
        echo "📦 Configuración manual..."
        provider="Proveedor personalizado"
        firewall_note="Tu firewall"
        ;;
esac

echo ""
echo "============================================================"
echo " INFORMACIÓN REQUERIDA"
echo "============================================================"
echo ""

read -p "Dominio (ej: tudominio.com): " domain
read -p "Email para certificados (ej: admin@tudominio.com): " email
read -p "Tu IP pública: " public_ip
read -sp "Contraseña PostgreSQL (mínimo 12 caracteres): " db_password
echo ""

# Validar contraseña
if [ ${#db_password} -lt 12 ]; then
    echo "[FAILED] Contraseña muy corta (mínimo 12 caracteres)"
    exit 1
fi

# Generar SECRET_KEY
secret_key=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")

echo ""
echo "============================================================"
echo " INFORMACIÓN GENERADA"
echo "============================================================"
echo ""
echo "Domain: $domain"
echo "Email: $email"
echo "Public IP: $public_ip"
echo "DB Password: [CONFIGURADO]"
echo "SECRET_KEY: [GENERADO]"
echo ""

read -p "¿Confirmar configuración? (s/n): " confirm
if [ "$confirm" != "s" ]; then
    echo "Cancelado."
    exit 1
fi

echo ""
echo "============================================================"
echo "⚙️  ACTUALIZANDO .env"
echo "============================================================"
echo ""

# Backup de .env si existe
if [ -f ".env" ]; then
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    echo " Backup de .env anterior guardado"
fi

# Crear .env para producción
cat > .env << EOF
# ===============================================================
# AQUADETECTION - CONFIGURACIÓN DE PRODUCCIÓN EN NUBE
# Generado: $(date)
# Proveedor: $provider
# ===============================================================

# === SSL/TLS CERTIFICADOS ===
DOMAIN_NAME=$domain
EMAIL=$email
CERT_TYPE=letsencrypt

# === SEGURIDAD DE ACCESO ===
ALLOWED_IP=$public_ip

# === BASE DE DATOS ===
POSTGRES_USER=aquadetection
POSTGRES_PASSWORD=$db_password
POSTGRES_DB=aquadetection_db
DATABASE_URL=postgresql://aquadetection:$db_password@db:5432/aquadetection_db

# === SEGURIDAD DEL BACKEND ===
SECRET_KEY=$secret_key
ACCESS_TOKEN_EXPIRE_MINUTES=11520  # 8 días

# === ENCRIPTACIÓN ===
DB_ENCRYPTION_KEY=YWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWE=

# === APIs EXTERNAS (OPCIONAL - Configurar si necesario) ===
VT_API_KEY=
HA_API_KEY=
ABUSEIPDB_API_KEY=
MALSHARE_API_KEY=
MALWAREBAZAAR_API_KEY=
PT_API_KEY=

# === SANDBOX (OPCIONAL - Configurar si necesario) ===
CUCKOO_API_URL=
CUCKOO_API_KEY=
CAPE_API_URL=
CAPE_API_KEY=
EOF

echo " .env actualizado con configuración de producción"
echo ""

echo "============================================================"
echo " PRE-DEPLOYMENT CHECKLIST"
echo "============================================================"
echo ""

checklist=(
    "DNS configurado: $domain → $public_ip"
    "Puertos 80, 443 abiertos en $firewall_note"
    "Docker instalado (sudo docker ps)"
    "Código en la instancia"
)

for i in "${!checklist[@]}"; do
    echo "$((i+1)). ${checklist[$i]}"
done

echo ""
read -p "¿Todos los puntos están completos? (s/n): " checklist_ok
if [ "$checklist_ok" != "s" ]; then
    echo "Por favor completa los pasos del checklist."
    echo "Luego ejecuta: sudo docker compose up --build -d"
    exit 1
fi

echo ""
echo "============================================================"
echo " INICIANDO DEPLOYMENT"
echo "============================================================"
echo ""

# Validar Docker
if ! command -v docker &> /dev/null; then
    echo "[FAILED] Docker no está instalado"
    echo "Instala Docker: https://get.docker.com"
    exit 1
fi

echo " Docker disponible"
echo ""

echo "📦 Construyendo imágenes (esto puede tomar varios minutos)..."
sudo docker compose build

echo ""
echo " Levantando servicios..."
sudo docker compose up -d

echo ""
echo "⏳ Esperando a que se generen certificados (60 segundos)..."
sleep 60

echo ""
echo "============================================================"
echo "[OK] DEPLOYMENT COMPLETADO"
echo "============================================================"
echo ""

echo " Verificando servicios..."
echo ""
sudo docker compose ps
echo ""

echo " Verificando certificados..."
sudo docker compose exec -T nginx certbot certificates | grep -A 5 "Certificate Name" || echo "⏳ Aún generando certificados..."

echo ""
echo "============================================================"
echo " PRÓXIMOS PASOS"
echo "============================================================"
echo ""
echo "1. Espera 5-10 minutos para que los certificados se generen completamente"
echo ""
echo "2. Verifica el certificado:"
echo "   curl https://$domain/"
echo ""
echo "3. Accede a la aplicación:"
echo "   https://$domain"
echo ""
echo "4. Ver logs:"
echo "   sudo docker compose logs -f"
echo ""
echo "5. Para problemas:"
echo "   sudo docker compose logs nginx | grep -i error"
echo ""
echo "============================================================"
echo "🎉 ¡Deployment iniciado!"
echo "============================================================"
echo ""
echo "Información guardada en .env (PROTEGE ESTE ARCHIVO)"
echo ""

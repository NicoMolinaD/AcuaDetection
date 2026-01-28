#!/bin/bash

# Script de Despliegue en Nube
# Facilita la configuración y despliegue en AWS, Azure, GCP, etc.

set -e

echo "============================================================"
echo " AcuaDetection - Despliegue en Nube"
echo "============================================================"
echo ""

# Verificar si estamos en el directorio correcto
if [ ! -f "docker-compose.yml" ]; then
    echo "[FALLO] Error: docker-compose.yml no encontrado"
    echo "Ejecute este script desde el directorio raíz del proyecto"
    exit 1
fi

# Menú interactivo
echo "Seleccione su proveedor de nube:"
echo "1) AWS (EC2)"
echo "2) Azure (VM)"
echo "3) Google Cloud (Compute Engine)"
echo "4) Otro (Configuración manual)"
echo ""
read -p "Opción (1-4): " provider_choice

case $provider_choice in
    1)
        echo "Configurando para AWS EC2..."
        provider="AWS EC2"
        firewall_note="AWS Security Group"
        ;;
    2)
        echo "Configurando para Azure VM..."
        provider="Azure VM"
        firewall_note="Azure Network Security Group (NSG)"
        ;;
    3)
        echo "Configurando para Google Cloud..."
        provider="Google Cloud Compute Engine"
        firewall_note="Google Cloud Firewall"
        ;;
    *)
        echo "Configuración manual..."
        provider="Proveedor personalizado"
        firewall_note="Su firewall"
        ;;
esac

echo ""
echo "============================================================"
echo " INFORMACIÓN REQUERIDA"
echo "============================================================"
echo ""

read -p "Dominio (ej: tudominio.com): " domain
read -p "Correo electrónico para certificados (ej: admin@tudominio.com): " email
read -p "Su IP pública: " public_ip
read -sp "Contraseña PostgreSQL (mínimo 12 caracteres): " db_password
echo ""

# Validar contraseña
if [ ${#db_password} -lt 12 ]; then
    echo "[FALLO] Contraseña muy corta (mínimo 12 caracteres)"
    exit 1
fi

# Generar SECRET_KEY
secret_key=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")

echo ""
echo "============================================================"
echo " INFORMACIÓN GENERADA"
echo "============================================================"
echo ""
echo "Dominio: $domain"
echo "Correo electrónico: $email"
echo "IP Pública: $public_ip"
echo "Contraseña BD: [CONFIGURADA]"
echo "SECRET_KEY: [GENERADA]"
echo ""

read -p "Confirme la configuración (s/n): " confirm
if [ "$confirm" != "s" ] && [ "$confirm" != "S" ]; then
    echo "Operación cancelada."
    exit 1
fi

echo ""
echo "============================================================"
echo "Actualizando .env"
echo "============================================================"
echo ""

# Copia de seguridad de .env existente
if [ -f ".env" ]; then
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    echo " Copia de seguridad de .env anterior guardada"
fi

# Crear .env para producción
cat > .env << EOF
# ===============================================================
# AQUADETECTION - CONFIGURACIÓN DE PRODUCCIÓN EN NUBE
# Generado: $(date)
# Proveedor: $provider
# ===============================================================

# === CERTIFICADOS SSL/TLS ===
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

# === APIs EXTERNAS (OPCIONAL - Configurar si es necesario) ===
VT_API_KEY=
HA_API_KEY=
ABUSEIPDB_API_KEY=
MALSHARE_API_KEY=
MALWAREBAZAAR_API_KEY=
PT_API_KEY=

# === SANDBOX (OPCIONAL - Configurar si es necesario) ===
CUCKOO_API_URL=
CUCKOO_API_KEY=
CAPE_API_URL=
CAPE_API_KEY=
EOF

echo " .env actualizado con configuración de producción"
echo ""

echo "============================================================"
echo " LISTA DE VERIFICACIÓN PREVIA AL DESPLIEGUE"
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
read -p "¿Están todos los elementos de la lista completados? (s/n): " checklist_ok
if [ "$checklist_ok" != "s" ] && [ "$checklist_ok" != "S" ]; then
    echo "Complete todos los elementos de la lista."
    echo "Luego ejecute: docker compose up --build -d"
    exit 1
fi

echo ""
echo "============================================================"
echo " Iniciando Despliegue"
echo "============================================================"
echo ""

# Validar Docker
if ! command -v docker &> /dev/null; then
    echo "[ERROR] Docker no está instalado"
    echo "Instale Docker: https://get.docker.com"
    exit 1
fi

echo " Docker está disponible"
echo ""

echo "Construyendo imágenes (esto puede tomar varios minutos)"
docker compose build

echo ""
echo " Iniciando servicios"
docker compose up -d

echo ""
echo "Esperando generación de certificados (60 segundos)"
sleep 60

echo ""
echo "============================================================"
echo "[EXITOSO] Despliegue Completado"
echo "============================================================"
echo ""

echo " Verificando servicios"
echo ""
docker compose ps
echo ""

echo " Verificando certificados"
docker compose exec -T nginx certbot certificates | grep -A 5 "Certificate Name" || echo "Generación de certificado en progreso"

echo ""
echo "============================================================"
echo " Próximos Pasos"
echo "============================================================"
echo ""
echo "1. Espere 5-10 minutos para que los certificados se generen completamente"
echo ""
echo "2. Verifique el certificado:"
echo "   curl https://$domain/"
echo ""
echo "3. Acceda a la aplicación:"
echo "   https://$domain"
echo ""
echo "4. Vea los registros:"
echo "   docker compose logs -f"
echo ""
echo "5. Para solucionar problemas:"
echo "   docker compose logs nginx | grep -i error"
echo ""
echo "============================================================"
echo " Despliegue Iniciado"
echo "============================================================"
echo ""
echo "Configuración guardada en .env (Proteja este archivo)"
echo ""


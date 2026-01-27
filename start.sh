#!/bin/bash

# AcuaDetection startup script

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Funciones
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Banner
echo -e "${BLUE}"
echo "=========================================="
echo "AcuaDetection - Startup"
echo "=========================================="
echo -e "${NC}"

# Step 1: Check Docker
log_info "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    log_error "Docker no está instalado. Instálalo primero."
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    log_error "Docker no está corriendo. Inicia con: systemctl start docker"
    exit 1
fi

log_success "Docker está disponible"

# Detect Detectar comando Docker
if docker ps >/dev/null 2>&1; then
    DOCKER_CMD="docker"
    log_success "Usando 'docker' sin sudo"
else
    DOCKER_CMD="sudo docker"
    log_warning "Usando 'sudo docker' (considera: usermod -aG docker usuario)"
fi

# Verify Verificar .env
log_info "Verificando archivo .env..."
if [ ! -f .env ]; then
    log_warning ".env no existe. Creando desde .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
        log_success ".env creado desde template"
    else
        log_error ".env ni .env.example encontrados"
        exit 1
    fi
else
    log_success ".env existe"
fi

# Build Construir imágenes
log_info "Construyendo imágenes Docker..."
$DOCKER_CMD compose build --no-cache 2>&1 | grep -E "^(Step|Built|built|Successfully)" || true

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    log_success "Imágenes construidas exitosamente"
else
    log_error "Error construyendo imágenes"
    exit 1
fi

# Start Iniciar contenedores
log_info "Iniciando contenedores (Nginx, Frontend, Backend, PostgreSQL)..."
$DOCKER_CMD compose up -d

log_success "Contenedores iniciados"

# Wait Esperar a que PostgreSQL esté listo
log_info "Esperando a que PostgreSQL esté disponible..."
for i in {1..30}; do
    if $DOCKER_CMD compose exec -T db pg_isready -U aquadetection >/dev/null 2>&1; then
        log_success "PostgreSQL está disponible"
        break
    fi
    echo -ne "  Intento $i/30...\r"
    sleep 1
done

# Wait Esperar a que Nginx esté listo y certificados generados
log_info "Esperando a que Backend esté listo..."
for i in {1..30}; do
    if $DOCKER_CMD compose exec -T backend curl -s http://localhost:8000/health >/dev/null 2>&1; then
        log_success "Backend está respondiendo"
        break
    fi
    echo -ne "  Intento $i/30...\r"
    sleep 1
done

log_info "Esperando a que Nginx esté listo..."
for i in {1..30}; do
    if $DOCKER_CMD compose exec -T nginx test -f /etc/nginx/nginx.conf 2>/dev/null; then
        log_success "Nginx está activo"
        break
    fi
    echo -ne "  Intento $i/30...\r"
    sleep 1
done

# Get IPs
PUBLIC_IP=$(hostname -I | awk '{print $1}')
DOMAIN="aquadetection.local"

# Check Verificar estado de todos los servicios
log_info "Verificando estado de servicios..."
SERVICE_STATUS=$($DOCKER_CMD compose ps)
if echo "$SERVICE_STATUS" | grep -q "running"; then
    log_success "Servicios en estado 'running'"
else
    log_warning "Algunos servicios podrían no estar listos"
fi

# Display Información final
echo -e "\n${GREEN}========== SISTEMA INICIADO CORRECTAMENTE ==========${NC}\n"

echo "Acceso a AcuaDetection:"
echo -e "  HTTP (localhost):    ${GREEN}http://localhost:8080${NC}"
echo -e "  HTTPS (IP):          ${GREEN}https://$PUBLIC_IP:8443${NC}"
echo -e "  HTTPS (Dominio):     ${GREEN}https://$DOMAIN:8443${NC}"
echo -e "  API Backend:         ${GREEN}http://localhost:8080/api/v1${NC}"
echo ""
echo "Puertos mapeados:"
echo -e "  HTTP:  ${GREEN}0.0.0.0:8080 -> nginx:80${NC}"
echo -e "  HTTPS: ${GREEN}0.0.0.0:8443 -> nginx:443${NC}"
echo ""
echo "Comandos útiles:"
echo -e "  Ver todos los logs:  ${BLUE}docker compose logs -f${NC}"
echo -e "  Ver logs backend:    ${BLUE}docker compose logs -f backend${NC}"
echo -e "  Ver logs nginx:      ${BLUE}docker compose logs -f nginx${NC}"
echo -e "  Ver logs postgres:   ${BLUE}docker compose logs -f db${NC}"
echo -e "  Estado servicios:    ${BLUE}docker compose ps${NC}"
echo -e "  Detener sistema:     ${BLUE}./stop.sh${NC}"
echo ""
echo -e "Credenciales por defecto:"
echo -e "  Admin:  ${GREEN}admin${NC}  / ${GREEN}admin123${NC}"
echo -e "  User:   ${GREEN}user${NC}   / ${GREEN}user123${NC}"
echo ""
echo -e "${YELLOW}NOTA: Los certificados SSL son autofirmados en desarrollo.${NC}"
echo -e "${YELLOW}      En producción, configura Let's Encrypt en infrastructure/nginx/init_certbot.sh${NC}"
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Sistema AcuaDetection listo para usar${NC}"
echo -e "${GREEN}================================================${NC}\n"

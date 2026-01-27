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
    if $DOCKER_CMD compose exec -T db pg_isready -U aquadetection_user >/dev/null 2>&1; then
        log_success "PostgreSQL está disponible"
        break
    fi
    echo -ne "  Intento $i/30...\r"
    sleep 1
done

# Wait Esperar a que Nginx esté listo y certificados generados
log_info "Esperando a que Nginx y certificados estén listos..."
for i in {1..60}; do
    if $DOCKER_CMD compose exec -T nginx test -f /etc/letsencrypt/live/aquadetection.local/fullchain.pem 2>/dev/null; then
        log_success "Certificados SSL/TLS generados"
        break
    fi
    echo -ne "  Generando certificados... $i/60\r"
    sleep 1
done

# Check Verificar que Nginx está respondiendo
log_info "Verificando que Nginx está respondiendo..."
for i in {1..15}; do
    if $DOCKER_CMD compose exec -T nginx curl -s https://localhost/api/v1 >/dev/null 2>&1; then
        log_success "Nginx está respondiendo correctamente"
        break
    fi
    echo -ne "  Intento $i/15...\r"
    sleep 1
done

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
echo -e "  HTTPS (Dominio):    ${GREEN}https://aquadetection.local${NC}"
echo -e "  HTTPS (IP):         ${GREEN}https://10.3.11.101${NC}"
echo -e "  API Docs (Swagger): ${GREEN}https://aquadetection.local/api/v1/docs${NC}"
echo -e "  API ReDoc:          ${GREEN}https://aquadetection.local/api/v1/redoc${NC}"
echo ""
echo "Puertos internos (solo Docker):"
echo -e "  Frontend:  ${GREEN}http://localhost:3000${NC}"
echo -e "  Backend:   ${GREEN}http://localhost:8000${NC}"
echo -e "  Database:  ${GREEN}127.0.0.1:5433${NC}"
echo ""
echo "Comandos útiles:"
echo -e "  Ver logs:              ${BLUE}docker-compose logs -f${NC}"
echo -e "  Ver logs Nginx:        ${BLUE}docker-compose logs -f nginx${NC}"
echo -e "  Estado servicios:      ${BLUE}docker-compose ps${NC}"
echo -e "  Detener sistema:       ${BLUE}./stop.sh${NC}"
echo ""
echo -e "${YELLOW}NOTA: El primer acceso mostrará advertencia SSL (certificado autofirmado).${NC}"
echo -e "${YELLOW}      Acepta continuar. Para producción, usa Let's Encrypt.${NC}"
echo ""
echo -e "Credenciales por defecto:"
echo -e "  Usuario: ${GREEN}admin${NC}  |  Contraseña: ${GREEN}admin123${NC}"
echo -e "  Usuario: ${GREEN}user${NC}   |  Contraseña: ${GREEN}user123${NC}"
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Sistema AcuaDetection listo para usar${NC}"
echo -e "${GREEN}================================================${NC}\n"

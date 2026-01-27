#!/bin/bash

# AcuaDetection Startup Script - Servidor Privado Local

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
echo "    AcuaDetection - Servidor Local"
echo "=========================================="
echo -e "${NC}"

# Detectar comando docker
if docker ps >/dev/null 2>&1; then
    DOCKER_CMD="docker"
    log_success "Usando 'docker' sin sudo"
else
    DOCKER_CMD="sudo docker"
    log_warning "Usando 'sudo docker'"
fi

# Verificar .env
if [ -f .env ]; then
    log_success ".env existe"
else
    log_warning ".env no existe, usando configuración por defecto"
fi

# Verificar Docker
log_info "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    log_error "Docker no está instalado"
    exit 1
fi

if ! $DOCKER_CMD info >/dev/null 2>&1; then
    log_error "Docker daemon no está corriendo"
    exit 1
fi

log_success "Docker disponible"

# Construir imágenes
log_info "Construyendo imágenes Docker..."
$DOCKER_CMD compose build --no-cache 2>&1 | tail -5
log_success "Imágenes construidas"

# Iniciar contenedores
log_info "Iniciando contenedores..."
$DOCKER_CMD compose up -d
log_success "Contenedores iniciados"

# Verificar servicios
log_info "Verificando servicios..."

echo -n "  PostgreSQL: "
for i in {1..30}; do
    if $DOCKER_CMD compose exec -T db pg_isready -U aquadetection >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        break
    fi
    [ $i -eq 30 ] && echo -e "${RED}✗${NC}" || echo -n "."
    sleep 1
done

echo -n "  Backend: "
for i in {1..30}; do
    if $DOCKER_CMD compose exec -T backend curl -s http://localhost:8000/health >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        break
    fi
    [ $i -eq 30 ] && echo -e "${RED}✗${NC}" || echo -n "."
    sleep 1
done

echo -n "  Frontend: "
for i in {1..10}; do
    if $DOCKER_CMD compose exec -T frontend test -f /usr/share/nginx/html/index.html 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        break
    fi
    [ $i -eq 10 ] && echo -e "${RED}✗${NC}" || echo -n "."
    sleep 1
done

echo -n "  Nginx: "
for i in {1..10}; do
    if $DOCKER_CMD compose exec -T nginx test -f /etc/nginx/nginx.conf 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        break
    fi
    [ $i -eq 10 ] && echo -e "${RED}✗${NC}" || echo -n "."
    sleep 1
done

# Obtener IP
LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "10.3.11.101")

# Información final
echo ""
echo -e "${GREEN}========== SISTEMA INICIADO CORRECTAMENTE ==========${NC}"
echo ""

echo -e "${BLUE}Acceso (Red Privada Local):${NC}"
echo -e "  HTTP:   ${GREEN}http://$LOCAL_IP:8080${NC}"
echo -e "  HTTPS:  ${GREEN}https://$LOCAL_IP:8443${NC}"
echo ""

echo -e "${BLUE}URLs de Aplicación:${NC}"
echo -e "  UI:      ${GREEN}https://$LOCAL_IP:8443${NC}"
echo -e "  API:     ${GREEN}https://$LOCAL_IP:8443/api/v1${NC}"
echo -e "  Docs:    ${GREEN}https://$LOCAL_IP:8443/api/v1/docs${NC}"
echo -e "  Health:  ${GREEN}https://$LOCAL_IP:8443/health${NC}"
echo ""

echo -e "${BLUE}Puertos Expuestos:${NC}"
echo -e "  HTTP (8080):  0.0.0.0:8080"
echo -e "  HTTPS (8443): 0.0.0.0:8443"
echo ""

echo -e "${BLUE}Credenciales por defecto:${NC}"
echo -e "  Admin: ${GREEN}admin${NC} / ${GREEN}admin123${NC}"
echo -e "  User:  ${GREEN}user${NC} / ${GREEN}user123${NC}"
echo ""

echo -e "${BLUE}Comandos útiles:${NC}"
echo -e "  Ver logs:      ${BLUE}docker compose logs -f${NC}"
echo -e "  Ver logs nginx: ${BLUE}docker compose logs -f nginx${NC}"
echo -e "  Estado:        ${BLUE}docker compose ps${NC}"
echo -e "  Detener:       ${BLUE}./stop.sh${NC}"
echo ""

echo -e "${YELLOW}NOTA: Certificados autofirmados para red privada${NC}"
echo -e "${YELLOW}      Se aceptará advertencia de seguridad en navegador${NC}"
echo ""

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Sistema listo para usar (Red Privada)${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Inicializar BD si es primera vez
if ! $DOCKER_CMD compose exec -T db psql -U aquadetection -d aquadetection_db -c "SELECT 1 FROM pg_tables WHERE tablename='user';" >/dev/null 2>&1; then
    log_info "Inicializando base de datos..."
    $DOCKER_CMD compose exec backend python init_db.py
    log_success "Base de datos inicializada"
fi

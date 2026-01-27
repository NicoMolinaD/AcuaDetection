#!/bin/bash

# AcuaDetection Production Startup Script

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
echo "    AcuaDetection - Production Deploy"
echo "=========================================="
echo -e "${NC}"

# ============ CONFIGURACIÓN ============

# Detectar comando docker
if docker ps >/dev/null 2>&1; then
    DOCKER_CMD="docker"
    log_success "Usando 'docker' sin sudo"
else
    DOCKER_CMD="sudo docker"
    log_warning "Usando 'sudo docker'"
fi

# Leer variables de .env o usar valores por defecto
if [ -f .env ]; then
    log_success ".env existe"
    set -a
    source .env
    set +a
fi

# Si DOMAIN_NAME no está configurado, preguntar
if [ -z "$DOMAIN_NAME" ] || [ "$DOMAIN_NAME" = "aquadetection.local" ]; then
    echo -e "\n${YELLOW}=== CONFIGURACIÓN REQUERIDA ===${NC}"
    read -p "Ingresa tu dominio (ej: aquadetection.example.com): " DOMAIN_INPUT
    if [ ! -z "$DOMAIN_INPUT" ]; then
        DOMAIN_NAME="$DOMAIN_INPUT"
        if [ -f .env ]; then
            sed -i "s/DOMAIN_NAME=.*/DOMAIN_NAME=$DOMAIN_NAME/" .env
        else
            echo "DOMAIN_NAME=$DOMAIN_NAME" >> .env
        fi
        log_success "Dominio configurado: $DOMAIN_NAME"
    fi
fi

DOMAIN_NAME="${DOMAIN_NAME:-aquadetection.local}"
EMAIL="${EMAIL:-admin@aquadetection.local}"

echo -e "\n${BLUE}Configuración:${NC}"
echo "  Dominio:  $DOMAIN_NAME"
echo "  Email:    $EMAIL"
echo ""

# ============ PRE-INICIO ============

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

# ============ CONSTRUIR Y INICIAR ============

log_info "Construyendo imágenes Docker..."
$DOCKER_CMD compose build --no-cache 2>&1 | tail -5
log_success "Imágenes construidas"

log_info "Iniciando contenedores..."
DOMAIN_NAME="$DOMAIN_NAME" EMAIL="$EMAIL" $DOCKER_CMD compose up -d
log_success "Contenedores iniciados"

# ============ VERIFICACIONES ============

log_info "Verificando servicios..."

# PostgreSQL
echo -n "  PostgreSQL: "
for i in {1..30}; do
    if $DOCKER_CMD compose exec -T db pg_isready -U aquadetection >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        break
    fi
    [ $i -eq 30 ] && echo -e "${RED}✗${NC}" || echo -n "."
    sleep 1
done

# Backend
echo -n "  Backend: "
for i in {1..30}; do
    if $DOCKER_CMD compose exec -T backend curl -s http://localhost:8000/health >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        break
    fi
    [ $i -eq 30 ] && echo -e "${RED}✗${NC}" || echo -n "."
    sleep 1
done

# Frontend
echo -n "  Frontend: "
for i in {1..10}; do
    if $DOCKER_CMD compose exec -T frontend test -f /usr/share/nginx/html/index.html 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        break
    fi
    [ $i -eq 10 ] && echo -e "${RED}✗${NC}" || echo -n "."
    sleep 1
done

# Nginx
echo -n "  Nginx: "
for i in {1..10}; do
    if $DOCKER_CMD compose exec -T nginx test -f /etc/nginx/nginx.conf 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        break
    fi
    [ $i -eq 10 ] && echo -e "${RED}✗${NC}" || echo -n "."
    sleep 1
done

# Obtener IPs
PUBLIC_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "YOUR_IP")

# ============ INFORMACIÓN FINAL ============

echo ""
echo -e "${GREEN}========== SISTEMA INICIADO CORRECTAMENTE ==========${NC}"
echo ""

echo -e "${BLUE}URLs de acceso:${NC}"
echo -e "  Producción:   ${GREEN}https://$DOMAIN_NAME${NC}"
echo -e "  IP Pública:   ${GREEN}https://$PUBLIC_IP${NC}"
echo -e "  Local (HTTP): ${BLUE}http://localhost${NC}"
echo ""

echo -e "${BLUE}APIs:${NC}"
echo -e "  Swagger:  ${GREEN}https://$DOMAIN_NAME/api/v1/docs${NC}"
echo -e "  ReDoc:    ${GREEN}https://$DOMAIN_NAME/api/v1/redoc${NC}"
echo -e "  Health:   ${GREEN}https://$DOMAIN_NAME/health${NC}"
echo ""

echo -e "${BLUE}Puertos expuestos:${NC}"
echo -e "  HTTP  (80):   0.0.0.0:80"
echo -e "  HTTPS (443):  0.0.0.0:443"
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

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Sistema listo para usar${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Inicializar BD si es primera vez
if ! $DOCKER_CMD compose exec -T db psql -U aquadetection -d aquadetection_db -c "SELECT 1 FROM pg_tables WHERE tablename='user';" >/dev/null 2>&1; then
    log_info "Inicializando base de datos..."
    $DOCKER_CMD compose exec backend python init_db.py
    log_success "Base de datos inicializada"
fi

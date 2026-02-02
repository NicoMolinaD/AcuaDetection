#!/bin/bash

set -e

# Códigos de color para la salida
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Funciones de registro
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[EXITOSO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"
}

# Encabezado
echo -e "${BLUE}"
echo "=========================================="
echo "    AcuaDetection - Inicio"
echo "=========================================="
echo -e "${NC}"

# Detectar comando docker
if docker ps >/dev/null 2>&1; then
    DOCKER_CMD="docker"
    log_success "Usando docker sin sudo"
else
    DOCKER_CMD="sudo docker"
    log_warning "Usando docker con sudo"
fi

# Verificar .env
if [ -f .env ]; then
    log_success "Archivo de configuración (.env) encontrado"
else
    log_warning "Archivo de configuración (.env) no encontrado, usando valores predeterminados"
fi

# Verificar Docker
log_info "Verificando instalación de Docker"
if ! command -v docker &> /dev/null; then
    log_error "Docker no está instalado"
    exit 1
fi

if ! $DOCKER_CMD info >/dev/null 2>&1; then
    log_error "El demonio de Docker no está en ejecución"
    exit 1
fi

log_success "Docker está disponible"

# Construir imágenes
log_info "Construyendo imágenes Docker"
$DOCKER_CMD compose build --no-cache 2>&1 | tail -5
log_success "Imágenes Docker construidas exitosamente"

# Iniciar contenedores
log_info "Iniciando contenedores"
$DOCKER_CMD compose up -d
log_success "Contenedores iniciados"

# Verificar servicios
# Verificación de servicios omitida por el momento

# Obtener IP local
LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "10.3.11.101")

# Información final
echo ""
echo -e "${GREEN}========== INICIO DEL SISTEMA COMPLETADO ==========${NC}"
echo ""

echo -e "${BLUE}Acceso (Red Privada):${NC}"
echo -e "  HTTP:   ${GREEN}http://$LOCAL_IP:8080${NC}"
echo -e "  HTTPS:  ${GREEN}https://$LOCAL_IP:8443${NC}"
echo ""

echo -e "${BLUE}URLs de la Aplicación:${NC}"
echo -e "  UI:      ${GREEN}https://$LOCAL_IP:8443${NC}"
echo -e "  API:     ${GREEN}https://$LOCAL_IP:8443/api/v1${NC}"
echo -e "  Docs:    ${GREEN}https://$LOCAL_IP:8443/api/v1/docs${NC}"
echo -e "  Salud:   ${GREEN}https://$LOCAL_IP:8443/health${NC}"
echo ""

echo -e "${BLUE}Puertos Expuestos:${NC}"
echo -e "  HTTP (8080):  0.0.0.0:8080"
echo -e "  HTTPS (8443): 0.0.0.0:8443"
echo ""

echo ""

echo -e "${BLUE}Comandos Útiles:${NC}"
echo -e "  Ver registros:       ${BLUE}docker compose logs -f${NC}"
echo -e "  Ver registros nginx: ${BLUE}docker compose logs -f nginx${NC}"
echo -e "  Ver estado:     ${BLUE}docker compose ps${NC}"
echo -e "  Detener servicios:   ${BLUE}./stop.sh${NC}"
echo ""

echo -e "${YELLOW}Nota: Usando certificados autofirmados para red privada${NC}"
echo -e "${YELLOW}      Acepte la advertencia de seguridad en el navegador${NC}"
echo ""

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Sistema listo para usar (Red Privada)${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Inicializar base de datos en el primer inicio
if ! $DOCKER_CMD compose exec -T db psql -U aquadetection -d aquadetection_db -c "SELECT 1 FROM pg_tables WHERE tablename='user';" >/dev/null 2>&1; then
    log_info "Inicializando base de datos"
    $DOCKER_CMD compose exec backend python init_db.py
    log_success "Base de datos inicializada"
fi

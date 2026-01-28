#!/bin/bash

set -e

# Códigos de color
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

mostrar_encabezado() {
    clear
    echo -e "${CYAN}========================================================${NC}"
    echo -e "${CYAN}${BOLD}Gestión de Usuarios - Sistema AcuaDetection${NC}"
    echo -e "${CYAN}========================================================${NC}"
    echo ""
}

verificar_docker() {
    if ! docker compose ps backend &>/dev/null; then
        echo -e "${RED}[ERROR] El contenedor del backend no está en ejecución${NC}"
        echo -e "${YELLOW}   Ejecute primero: ./start.sh${NC}"
        exit 1
    fi
}

pausa() {
    echo ""
    read -p "Presione ENTER para continuar"
}

# Crear nuevo usuario
crear_usuario() {
    mostrar_encabezado
    echo -e "${BLUE}Crear Nuevo Usuario${NC}\n"
    
    read -p "Nombre de usuario: " USERNAME
    
    if [ -z "$USERNAME" ]; then
        echo -e "${RED}[ERROR] El nombre de usuario no puede estar vacío${NC}"
        pausa
        return
    fi
    
    read -sp "Contraseña: " PASSWORD
    echo ""
    
    if [ -z "$PASSWORD" ]; then
        echo -e "${RED}[ERROR] La contraseña no puede estar vacía${NC}"
        pausa
        return
    fi
    
    read -p "¿Es administrador? (s/n): " ES_ADMIN
    
    if [ "$ES_ADMIN" = "s" ] || [ "$ES_ADMIN" = "S" ]; then
        BANDERA_ADMIN="True"
        ROL="Administrador"
    else
        BANDERA_ADMIN="False"
        ROL="Usuario Regular"
    fi
    
    echo -e "\n${BLUE}Creando usuario${NC}"
    
    RESULTADO=$(docker compose exec -T backend python -c "
from app.core.database import SessionLocal
from app.models.user import User
from app.core import security

db = SessionLocal()
try:
    existing = db.query(User).filter(User.username == '$USERNAME').first()
    if existing:
        print('ERROR:El usuario ya existe')
    else:
        user = User(username='$USERNAME', hashed_password=security.get_password_hash('$PASSWORD'), is_admin=$BANDERA_ADMIN)
        db.add(user)
        db.commit()
        print('SUCCESS:Usuario creado exitosamente')
finally:
    db.close()
" 2>&1)
    
    if echo "$RESULTADO" | grep -q "SUCCESS"; then
        echo -e "${GREEN}[EXITOSO] Usuario creado exitosamente:${NC}"
        echo -e "   Nombre de usuario: ${BOLD}$USERNAME${NC}"
        echo -e "   Rol: ${BOLD}$ROL${NC}"
    elif echo "$RESULTADO" | grep -q "ERROR"; then
        echo -e "${RED}[FALLO] El usuario '$USERNAME' ya existe${NC}"
    else
        echo -e "${RED}[FALLO] Error al crear usuario${NC}"
        echo -e "${YELLOW}Detalles: $RESULTADO${NC}"
    fi
    
    pausa
}

# Listar todos los usuarios
listar_usuarios() {
    mostrar_encabezado
    echo -e "${BLUE}=== Usuarios del Sistema ===${NC}\n"
    
    sudo docker compose exec -T backend python -c "
from app.core.database import SessionLocal
from app.models.user import User

db = SessionLocal()
try:
    users = db.query(User).all()
    if not users:
        print('No hay usuarios en el sistema')
    else:
        print(f'{'ID':<5} | {'Nombre de usuario':<20} | {'Rol':<15}')
        print('-' * 50)
        for user in users:
            role = 'Administrador' if user.is_admin else 'Usuario Regular'
            print(f'{user.id:<5} | {user.username:<20} | {role:<15}')
finally:
    db.close()
"
    
    pausa
}

# Cambiar contraseña
cambiar_contrasena() {
    mostrar_encabezado
    echo -e "${BLUE}=== Cambiar Contraseña de Usuario ===${NC}\n"
    
    read -p "Nombre de usuario: " USERNAME
    
    if [ -z "$USERNAME" ]; then
        echo -e "${RED}[FALLO] El nombre de usuario no puede estar vacío${NC}"
        pausa
        return
    fi
    
    read -sp "Nueva contraseña: " NUEVA_CONTRASENA
    echo ""
    
    if [ -z "$NUEVA_CONTRASENA" ]; then
        echo -e "${RED}[FALLO] La contraseña no puede estar vacía${NC}"
        pausa
        return
    fi
    
    read -sp "Confirmar contraseña: " CONFIRMAR_CONTRASENA
    echo ""
    
    if [ "$NUEVA_CONTRASENA" != "$CONFIRMAR_CONTRASENA" ]; then
        echo -e "${RED}[FALLO] Las contraseñas no coinciden${NC}"
        pausa
        return
    fi
    
    echo -e "\n${BLUE}Actualizando contraseña${NC}"
    
    RESULTADO=$(sudo docker compose exec -T backend python -c "
from app.core.database import SessionLocal
from app.models.user import User
from app.core import security

db = SessionLocal()
try:
    user = db.query(User).filter(User.username == '$USERNAME').first()
    if user:
        user.hashed_password = security.get_password_hash('$NUEVA_CONTRASENA')
        db.commit()
        print('SUCCESS:Contraseña actualizada')
    else:
        print('ERROR:Usuario no encontrado')
finally:
    db.close()
" 2>&1)
    
    if echo "$RESULTADO" | grep -q "SUCCESS"; then
        echo -e "${GREEN}[EXITOSO] Contraseña actualizada para '$USERNAME'${NC}"
    elif echo "$RESULTADO" | grep -q "ERROR"; then
        echo -e "${RED}[FALLO] Usuario '$USERNAME' no encontrado${NC}"
    else
        echo -e "${RED}[FALLO] Error al actualizar contraseña${NC}"
    fi
    
    pausa
}

# Promover a administrador
promover_usuario() {
    mostrar_encabezado
    echo -e "${BLUE}=== Promover Usuario a Administrador ===${NC}\n"
    
    read -p "Nombre de usuario: " USERNAME
    
    if [ -z "$USERNAME" ]; then
        echo -e "${RED}[FALLO] El nombre de usuario no puede estar vacío${NC}"
        pausa
        return
    fi
    
    echo -e "\n${BLUE}Promoviendo usuario${NC}"
    
    RESULTADO=$(sudo docker compose exec -T backend python -c "
from app.core.database import SessionLocal
from app.models.user import User

db = SessionLocal()
try:
    user = db.query(User).filter(User.username == '$USERNAME').first()
    if user:
        if user.is_admin:
            print('INFO:El usuario ya es administrador')
        else:
            user.is_admin = True
            db.commit()
            print('SUCCESS:Usuario promovido')
    else:
        print('ERROR:Usuario no encontrado')
finally:
    db.close()
" 2>&1)
    
    if echo "$RESULTADO" | grep -q "SUCCESS"; then
        echo -e "${GREEN}[EXITOSO]${NC} '$USERNAME' ahora es administrador"
    elif echo "$RESULTADO" | grep -q "INFO"; then
        echo -e "${YELLOW}[INFO]${NC} '$USERNAME' ya es administrador"
    elif echo "$RESULTADO" | grep -q "ERROR"; then
        echo -e "${RED}[ERROR]${NC} Usuario '$USERNAME' no encontrado"
    else
        echo -e "${RED}[ERROR]${NC} Error al promover usuario"
    fi
    
    pausa
}

# Degradar a usuario regular
degradar_usuario() {
    mostrar_encabezado
    echo -e "${BLUE}=== Degradar Administrador a Usuario Regular ===${NC}\n"
    
    read -p "Nombre de usuario: " USERNAME
    
    if [ -z "$USERNAME" ]; then
        echo -e "${RED}[FALLO] El nombre de usuario no puede estar vacío${NC}"
        pausa
        return
    fi
    
    echo -e "\n${BLUE}Degradando usuario${NC}"
    
    RESULTADO=$(sudo docker compose exec -T backend python -c "
from app.core.database import SessionLocal
from app.models.user import User

db = SessionLocal()
try:
    user = db.query(User).filter(User.username == '$USERNAME').first()
    if user:
        if not user.is_admin:
            print('INFO:El usuario ya es usuario regular')
        else:
            user.is_admin = False
            db.commit()
            print('SUCCESS:Usuario degradado')
    else:
        print('ERROR:Usuario no encontrado')
finally:
    db.close()
" 2>&1)
    
    if echo "$RESULTADO" | grep -q "SUCCESS"; then
        echo -e "${GREEN}[EXITOSO]${NC} '$USERNAME' ahora es usuario regular"
    elif echo "$RESULTADO" | grep -q "INFO"; then
        echo -e "${YELLOW}[INFO]${NC} '$USERNAME' ya es usuario regular"
    elif echo "$RESULTADO" | grep -q "ERROR"; then
        echo -e "${RED}[ERROR]${NC} Usuario '$USERNAME' no encontrado"
    else
        echo -e "${RED}[ERROR]${NC} Error al degradar usuario"
    fi
    
    pausa
}

# Eliminar usuario
eliminar_usuario() {
    mostrar_encabezado
    echo -e "${RED}=== Eliminar Usuario ===${NC}\n"
    echo -e "${YELLOW}[ADVERTENCIA]  Esta acción no se puede deshacer${NC}\n"
    
    read -p "Nombre de usuario a eliminar: " USERNAME
    
    if [ -z "$USERNAME" ]; then
        echo -e "${RED}[FALLO] El nombre de usuario no puede estar vacío${NC}"
        pausa
        return
    fi
    
    read -p "¿Está seguro de que desea eliminar a '$USERNAME'? (s/n): " CONFIRMAR
    
    if [ "$CONFIRMAR" != "s" ] && [ "$CONFIRMAR" != "S" ]; then
        echo -e "${YELLOW}Operación cancelada${NC}"
        pausa
        return
    fi
    
    echo -e "\n${BLUE}Eliminando usuario${NC}"
    
    RESULTADO=$(sudo docker compose exec -T backend python -c "
from app.core.database import SessionLocal
from app.models.user import User

db = SessionLocal()
try:
    user = db.query(User).filter(User.username == '$USERNAME').first()
    if user:
        db.delete(user)
        db.commit()
        print('SUCCESS:Usuario eliminado')
    else:
        print('ERROR:Usuario no encontrado')
finally:
    db.close()
" 2>&1)
    
    if echo "$RESULTADO" | grep -q "SUCCESS"; then
        echo -e "${GREEN}[EXITOSO] Usuario '$USERNAME' eliminado exitosamente${NC}"
    elif echo "$RESULTADO" | grep -q "ERROR"; then
        echo -e "${RED}[FALLO] Usuario '$USERNAME' no encontrado${NC}"
    else
        echo -e "${RED}[FALLO] Error al eliminar usuario${NC}"
    fi
    
    pausa
}

# Crear usuario rápido (sin confirmaciones)
creacion_rapida() {
    mostrar_encabezado
    echo -e "${BLUE}=== Creación Rápida de Usuario ===${NC}\n"
    echo -e "${YELLOW}Modo rápido: Usuario regular con nombre de usuario=contraseña${NC}\n"
    
    read -p "Nombre de usuario (será también la contraseña): " USERNAME
    
    if [ -z "$USERNAME" ]; then
        echo -e "${RED}[FALLO] El nombre de usuario no puede estar vacío${NC}"
        pausa
        return
    fi
    
    echo -e "\n${BLUE}Creando usuario${NC}"
    
    RESULTADO=$(sudo docker compose exec -T backend python -c "
from app.core.database import SessionLocal
from app.models.user import User
from app.core import security

db = SessionLocal()
try:
    existing = db.query(User).filter(User.username == '$USERNAME').first()
    if existing:
        print('ERROR:El usuario ya existe')
    else:
        user = User(username='$USERNAME', hashed_password=security.get_password_hash('$USERNAME'), is_admin=False)
        db.add(user)
        db.commit()
        print('SUCCESS:Usuario creado')
finally:
    db.close()
" 2>&1)
    
    if echo "$RESULTADO" | grep -q "SUCCESS"; then
        echo -e "${GREEN}[EXITOSO] Usuario creado exitosamente:${NC}"
        echo -e "   Nombre de usuario: ${BOLD}$USERNAME${NC}"
        echo -e "   Contraseña: ${BOLD}$USERNAME${NC}"
        echo -e "   Rol: ${BOLD}Usuario Regular${NC}"
    elif echo "$RESULTADO" | grep -q "ERROR"; then
        echo -e "${RED}[FALLO] El usuario '$USERNAME' ya existe${NC}"
    else
        echo -e "${RED}[FALLO] Error al crear usuario${NC}"
    fi
    
    pausa
}

# ============================================================================
# MENÚ PRINCIPAL
# ============================================================================

mostrar_menu() {
    mostrar_encabezado
    echo -e "${BOLD}Seleccione una opción:${NC}\n"
    echo -e "  ${GREEN}1.${NC} Crear nuevo usuario"
    echo -e "  ${GREEN}2.${NC} Listar todos los usuarios"
    echo -e "  ${GREEN}3.${NC} Cambiar contraseña de usuario"
    echo -e "  ${GREEN}4.${NC} Promover usuario a administrador"
    echo -e "  ${GREEN}5.${NC} Degradar administrador a usuario regular"
    echo -e "  ${GREEN}6.${NC} Eliminar usuario"
    echo -e "  ${CYAN}7.${NC} Creación rápida (nombre de usuario=contraseña)"
    echo -e "  ${RED}0.${NC} Salir"
    echo ""
    read -p "Opción: " OPCION
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    # Verificar que Docker esté corriendo
    verificar_docker
    
    while true; do
        mostrar_menu
        
        case $OPCION in
            1) crear_usuario ;;
            2) listar_usuarios ;;
            3) cambiar_contrasena ;;
            4) promover_usuario ;;
            5) degradar_usuario ;;
            6) eliminar_usuario ;;
            7) creacion_rapida ;;
            0) 
                echo -e "\n${GREEN}Saliendo${NC}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}[ERROR]${NC} Opción inválida"
                pausa
                ;;
        esac
    done
}

main

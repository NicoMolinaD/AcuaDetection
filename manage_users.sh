#!/bin/bash

# ============================================================================
# Script de Gestión de Usuarios - Malcom System
# ============================================================================

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Función para mostrar el banner
show_banner() {
    clear
    echo -e "${CYAN}+========================================================+${NC}"
    echo -e "${CYAN}|${NC}  ${BOLD}👥 GESTIÓN DE USUARIOS - MALCOM SYSTEM${NC}           ${CYAN}|${NC}"
    echo -e "${CYAN}╚========================================================╝${NC}"
    echo ""
}

# Función para verificar que Docker está corriendo
check_docker() {
    if ! sudo docker compose ps backend &>/dev/null; then
        echo -e "${RED}[FAILED] Error: El contenedor backend no está corriendo.${NC}"
        echo -e "${YELLOW}   Ejecuta primero: ./start.sh${NC}"
        exit 1
    fi
}

# Función para pausar y esperar input del usuario
pause() {
    echo ""
    read -p "Presiona ENTER para continuar..."
}

# ============================================================================
# OPERACIONES DE USUARIO
# ============================================================================

# 1. Crear nuevo usuario
create_user() {
    show_banner
    echo -e "${BLUE}=== Crear Nuevo Usuario ===${NC}\n"
    
    read -p "Username: " USERNAME
    
    # Validar que el username no esté vacío
    if [ -z "$USERNAME" ]; then
        echo -e "${RED}[FAILED] El username no puede estar vacío${NC}"
        pause
        return
    fi
    
    read -sp "Password: " PASSWORD
    echo ""
    
    # Validar que la password no esté vacía
    if [ -z "$PASSWORD" ]; then
        echo -e "${RED}[FAILED] La contraseña no puede estar vacía${NC}"
        pause
        return
    fi
    
    read -p "¿Es administrador? (s/n): " IS_ADMIN
    
    # Convertir respuesta a booleano Python
    if [ "$IS_ADMIN" = "s" ] || [ "$IS_ADMIN" = "S" ]; then
        ADMIN_FLAG="True"
        ROLE="Administrador"
    else
        ADMIN_FLAG="False"
        ROLE="Usuario Regular"
    fi
    
    echo -e "\n${BLUE}Creando usuario...${NC}"
    
    # Ejecutar comando
    RESULT=$(sudo docker compose exec -T backend python -c "
from app.core.database import SessionLocal
from app.models.user import User
from app.core import security

db = SessionLocal()
try:
    existing = db.query(User).filter(User.username == '$USERNAME').first()
    if existing:
        print('ERROR:El usuario ya existe')
    else:
        user = User(username='$USERNAME', hashed_password=security.get_password_hash('$PASSWORD'), is_admin=$ADMIN_FLAG)
        db.add(user)
        db.commit()
        print('SUCCESS:Usuario creado exitosamente')
finally:
    db.close()
" 2>&1)
    
    if echo "$RESULT" | grep -q "SUCCESS"; then
        echo -e "${GREEN}[OK] Usuario creado exitosamente:${NC}"
        echo -e "   Username: ${BOLD}$USERNAME${NC}"
        echo -e "   Role: ${BOLD}$ROLE${NC}"
    elif echo "$RESULT" | grep -q "ERROR"; then
        echo -e "${RED}[FAILED] El usuario '$USERNAME' ya existe${NC}"
    else
        echo -e "${RED}[FAILED] Error al crear usuario${NC}"
        echo -e "${YELLOW}Detalles: $RESULT${NC}"
    fi
    
    pause
}

# 2. Listar todos los usuarios
list_users() {
    show_banner
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
        print(f'{'ID':<5} | {'Username':<20} | {'Role':<15}')
        print('-' * 50)
        for user in users:
            role = 'Administrador' if user.is_admin else 'Usuario Regular'
            print(f'{user.id:<5} | {user.username:<20} | {role:<15}')
finally:
    db.close()
"
    
    pause
}

# 3. Cambiar contraseña
change_password() {
    show_banner
    echo -e "${BLUE}=== Cambiar Contraseña de Usuario ===${NC}\n"
    
    read -p "Username: " USERNAME
    
    if [ -z "$USERNAME" ]; then
        echo -e "${RED}[FAILED] El username no puede estar vacío${NC}"
        pause
        return
    fi
    
    read -sp "Nueva contraseña: " NEW_PASSWORD
    echo ""
    
    if [ -z "$NEW_PASSWORD" ]; then
        echo -e "${RED}[FAILED] La contraseña no puede estar vacía${NC}"
        pause
        return
    fi
    
    read -sp "Confirmar contraseña: " CONFIRM_PASSWORD
    echo ""
    
    if [ "$NEW_PASSWORD" != "$CONFIRM_PASSWORD" ]; then
        echo -e "${RED}[FAILED] Las contraseñas no coinciden${NC}"
        pause
        return
    fi
    
    echo -e "\n${BLUE}Actualizando contraseña...${NC}"
    
    RESULT=$(sudo docker compose exec -T backend python -c "
from app.core.database import SessionLocal
from app.models.user import User
from app.core import security

db = SessionLocal()
try:
    user = db.query(User).filter(User.username == '$USERNAME').first()
    if user:
        user.hashed_password = security.get_password_hash('$NEW_PASSWORD')
        db.commit()
        print('SUCCESS:Contraseña actualizada')
    else:
        print('ERROR:Usuario no encontrado')
finally:
    db.close()
" 2>&1)
    
    if echo "$RESULT" | grep -q "SUCCESS"; then
        echo -e "${GREEN}[OK] Contraseña actualizada para '$USERNAME'${NC}"
    elif echo "$RESULT" | grep -q "ERROR"; then
        echo -e "${RED}[FAILED] Usuario '$USERNAME' no encontrado${NC}"
    else
        echo -e "${RED}[FAILED] Error al actualizar contraseña${NC}"
    fi
    
    pause
}

# 4. Promover a administrador
promote_user() {
    show_banner
    echo -e "${BLUE}=== Promover Usuario a Administrador ===${NC}\n"
    
    read -p "Username: " USERNAME
    
    if [ -z "$USERNAME" ]; then
        echo -e "${RED}[FAILED] El username no puede estar vacío${NC}"
        pause
        return
    fi
    
    echo -e "\n${BLUE}Promoviendo usuario...${NC}"
    
    RESULT=$(sudo docker compose exec -T backend python -c "
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
    
    if echo "$RESULT" | grep -q "SUCCESS"; then
        echo -e "${GREEN}[OK] '$USERNAME' ahora es administrador${NC}"
    elif echo "$RESULT" | grep -q "INFO"; then
        echo -e "${YELLOW}ℹ️  '$USERNAME' ya es administrador${NC}"
    elif echo "$RESULT" | grep -q "ERROR"; then
        echo -e "${RED}[FAILED] Usuario '$USERNAME' no encontrado${NC}"
    else
        echo -e "${RED}[FAILED] Error al promover usuario${NC}"
    fi
    
    pause
}

# 5. Degradar a usuario regular
demote_user() {
    show_banner
    echo -e "${BLUE}=== Degradar Administrador a Usuario Regular ===${NC}\n"
    
    read -p "Username: " USERNAME
    
    if [ -z "$USERNAME" ]; then
        echo -e "${RED}[FAILED] El username no puede estar vacío${NC}"
        pause
        return
    fi
    
    echo -e "\n${BLUE}Degradando usuario...${NC}"
    
    RESULT=$(sudo docker compose exec -T backend python -c "
from app.core.database import SessionLocal
from app.models.user import User

db = SessionLocal()
try:
    user = db.query(User).filter(User.username == '$USERNAME').first()
    if user:
        if not user.is_admin:
            print('INFO:El usuario ya es regular')
        else:
            user.is_admin = False
            db.commit()
            print('SUCCESS:Usuario degradado')
    else:
        print('ERROR:Usuario no encontrado')
finally:
    db.close()
" 2>&1)
    
    if echo "$RESULT" | grep -q "SUCCESS"; then
        echo -e "${GREEN}[OK] '$USERNAME' ahora es usuario regular${NC}"
    elif echo "$RESULT" | grep -q "INFO"; then
        echo -e "${YELLOW}ℹ️  '$USERNAME' ya es usuario regular${NC}"
    elif echo "$RESULT" | grep -q "ERROR"; then
        echo -e "${RED}[FAILED] Usuario '$USERNAME' no encontrado${NC}"
    else
        echo -e "${RED}[FAILED] Error al degradar usuario${NC}"
    fi
    
    pause
}

# 6. Eliminar usuario
delete_user() {
    show_banner
    echo -e "${RED}=== Eliminar Usuario ===${NC}\n"
    echo -e "${YELLOW}[WARN]  ADVERTENCIA: Esta acción no se puede deshacer${NC}\n"
    
    read -p "Username a eliminar: " USERNAME
    
    if [ -z "$USERNAME" ]; then
        echo -e "${RED}[FAILED] El username no puede estar vacío${NC}"
        pause
        return
    fi
    
    read -p "¿Estás seguro de eliminar '$USERNAME'? (s/n): " CONFIRM
    
    if [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ]; then
        echo -e "${YELLOW}Operación cancelada${NC}"
        pause
        return
    fi
    
    echo -e "\n${BLUE}Eliminando usuario...${NC}"
    
    RESULT=$(sudo docker compose exec -T backend python -c "
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
    
    if echo "$RESULT" | grep -q "SUCCESS"; then
        echo -e "${GREEN}[OK] Usuario '$USERNAME' eliminado exitosamente${NC}"
    elif echo "$RESULT" | grep -q "ERROR"; then
        echo -e "${RED}[FAILED] Usuario '$USERNAME' no encontrado${NC}"
    else
        echo -e "${RED}[FAILED] Error al eliminar usuario${NC}"
    fi
    
    pause
}

# 7. Crear usuario rápido (sin confirmaciones)
quick_create() {
    show_banner
    echo -e "${BLUE}=== Creación Rápida de Usuario ===${NC}\n"
    echo -e "${YELLOW}Modo rápido: Usuario regular con username=password${NC}\n"
    
    read -p "Username (será también la contraseña): " USERNAME
    
    if [ -z "$USERNAME" ]; then
        echo -e "${RED}[FAILED] El username no puede estar vacío${NC}"
        pause
        return
    fi
    
    echo -e "\n${BLUE}Creando usuario...${NC}"
    
    RESULT=$(sudo docker compose exec -T backend python -c "
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
    
    if echo "$RESULT" | grep -q "SUCCESS"; then
        echo -e "${GREEN}[OK] Usuario creado exitosamente:${NC}"
        echo -e "   Username: ${BOLD}$USERNAME${NC}"
        echo -e "   Password: ${BOLD}$USERNAME${NC}"
        echo -e "   Role: ${BOLD}Usuario Regular${NC}"
    elif echo "$RESULT" | grep -q "ERROR"; then
        echo -e "${RED}[FAILED] El usuario '$USERNAME' ya existe${NC}"
    else
        echo -e "${RED}[FAILED] Error al crear usuario${NC}"
    fi
    
    pause
}

# ============================================================================
# MENÚ PRINCIPAL
# ============================================================================

show_menu() {
    show_banner
    echo -e "${BOLD}Selecciona una opción:${NC}\n"
    echo -e "  ${GREEN}1.${NC} Crear nuevo usuario"
    echo -e "  ${GREEN}2.${NC} Listar todos los usuarios"
    echo -e "  ${GREEN}3.${NC} Cambiar contraseña de usuario"
    echo -e "  ${GREEN}4.${NC} Promover usuario a administrador"
    echo -e "  ${GREEN}5.${NC} Degradar administrador a usuario regular"
    echo -e "  ${GREEN}6.${NC} Eliminar usuario"
    echo -e "  ${CYAN}7.${NC} Creación rápida (username=password)"
    echo -e "  ${RED}0.${NC} Salir"
    echo ""
    read -p "Opción: " OPTION
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    # Verificar que Docker esté corriendo
    check_docker
    
    while true; do
        show_menu
        
        case $OPTION in
            1) create_user ;;
            2) list_users ;;
            3) change_password ;;
            4) promote_user ;;
            5) demote_user ;;
            6) delete_user ;;
            7) quick_create ;;
            0) 
                echo -e "\n${GREEN}¡Hasta luego!${NC}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}[FAILED] Opción inválida${NC}"
                pause
                ;;
        esac
    done
}

# Ejecutar el script
main

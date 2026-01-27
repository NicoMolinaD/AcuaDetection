#!/bin/bash

# Script rápido para crear usuarios con argumentos de línea de comandos
# Uso: ./quick_user.sh <username> [password] [admin]

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verificar argumentos
if [ $# -lt 1 ]; then
    echo -e "${RED}Uso: $0 <username> [password] [admin]${NC}"
    echo ""
    echo "Ejemplos:"
    echo "  $0 analyst1                    # Crea usuario regular, password=username"
    echo "  $0 analyst1 mypass123          # Crea usuario regular con password específica"
    echo "  $0 admin1 admin123 admin       # Crea administrador"
    exit 1
fi

USERNAME=$1
PASSWORD=${2:-$USERNAME}  # Si no se proporciona password, usar username
IS_ADMIN=${3:-""}

# Determinar si es admin
if [ "$IS_ADMIN" = "admin" ] || [ "$IS_ADMIN" = "true" ]; then
    ADMIN_FLAG="True"
    ROLE="Administrador"
else
    ADMIN_FLAG="False"
    ROLE="Usuario Regular"
fi

echo -e "${YELLOW}Creando usuario...${NC}"

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
        print('SUCCESS:Usuario creado')
finally:
    db.close()
" 2>&1)

if echo "$RESULT" | grep -q "SUCCESS"; then
    echo -e "${GREEN}[OK] Usuario creado exitosamente:${NC}"
    echo -e "   Username: $USERNAME"
    echo -e "   Password: $PASSWORD"
    echo -e "   Role: $ROLE"
else
    echo -e "${RED}[FAILED] Error: El usuario '$USERNAME' ya existe${NC}"
    exit 1
fi

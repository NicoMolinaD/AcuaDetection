#!/bin/bash

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE} Inicializando la base de datos...${NC}"

# Ejecutar el script de inicialización dentro del contenedor del backend
if ! docker info >/dev/null 2>&1; then
  sudo docker compose exec backend python init_db.py
else
  docker compose exec backend python init_db.py
fi

echo -e "${GREEN}[OK] Base de datos inicializada${NC}"
echo -e "Puedes iniciar sesión con:"
echo -e "  Usuario Admin: ${GREEN}admin${NC} / Contraseña: ${GREEN}Ad.m¡n1sTer.#2O26!${NC}"
echo -e "  Usuario Regular: ${GREEN}user${NC} / Contraseña: ${GREEN}user123${NC}"

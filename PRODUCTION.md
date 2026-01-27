# 🚀 AcuaDetection - Guía de Despliegue en Producción

## Prerrequisitos

- Docker y Docker Compose instalados
- Un dominio propio (ej: `aquadetection.example.com`)
- Puerto 80 y 443 accesibles desde internet
- Email válido para Let's Encrypt

## Instalación Rápida

### 1. Configurar el dominio

```bash
# Opción A: Editar .env directamente
cp .env.production .env
# Editar .env y cambiar:
# DOMAIN_NAME=tu-dominio.com
# EMAIL=tu-email@example.com

# Opción B: Configuración interactiva
./start.sh  # Te pedirá el dominio si no está configurado
```

### 2. Configurar DNS

**En tu proveedor DNS, apunta tu dominio a la IP de tu servidor:**

```
A     aquadetection.example.com    → 10.3.11.101 (tu IP)
```

**Espera a que DNS se propague (5-15 minutos):**
```bash
nslookup aquadetection.example.com
# O con dig
dig aquadetection.example.com
```

### 3. Iniciar el sistema

```bash
chmod +x start.sh
./start.sh
```

El script hará:
- ✅ Construir imágenes Docker
- ✅ Levantar todos los servicios  
- ✅ Obtener certificado SSL de Let's Encrypt automáticamente
- ✅ Inicializar la base de datos
- ✅ Verificar que todos los servicios responden

## Acceso

Una vez iniciado, accede a:

- **UI:** https://aquadetection.example.com
- **API Swagger:** https://aquadetection.example.com/api/v1/docs
- **API ReDoc:** https://aquadetection.example.com/api/v1/redoc
- **Health Check:** https://aquadetection.example.com/health

### Credenciales por defecto

```
Usuario: admin
Contraseña: admin123
```

**⚠️ IMPORTANTE:** Cambia la contraseña después del primer acceso.

## Puertos

El sistema escucha en puertos estándar:

- **Puerto 80 (HTTP):** Redirige automáticamente a HTTPS
- **Puerto 443 (HTTPS):** Acceso seguro con certificado Let's Encrypt

No necesitas puertos personalizados como `8080` o `8443`.

## Certificados SSL

### Let's Encrypt (Automático)

El sistema obtiene certificados automáticamente de Let's Encrypt en el primer inicio:

```bash
./start.sh
# Durante el inicio, verás:
# [INFO] Intentando obtener certificado de Let's Encrypt...
# [OK] Certificado de Let's Encrypt obtenido exitosamente
```

**Renovación automática:** Los certificados se renuevan automáticamente 30 días antes del vencimiento.

### Usar certificado existente

Si tienes un certificado de otra fuente:

```bash
# Copiar a:
# /etc/letsencrypt/live/tu-dominio.com/fullchain.pem
# /etc/letsencrypt/live/tu-dominio.com/privkey.pem

# Reiniciar nginx:
docker compose restart nginx
```

## Configuración de Seguridad

### Variables de entorno importantes

En `.env`, configura:

```bash
# Seguridad
SECRET_KEY=tu-clave-secreta-aleatoria-fuerte

# Email para Let's Encrypt
EMAIL=admin@tu-dominio.com

# API Keys (VirusTotal, Hybrid Analysis, etc.)
VT_API_KEY=tu-clave-virustotal
HA_API_KEY=tu-clave-hybrid-analysis
```

### Firewall

```bash
# Permitir solo puertos necesarios
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp   # SSH (solo si lo necesitas)
```

## Monitoreo

### Ver logs en tiempo real

```bash
# Todos los logs
docker compose logs -f

# Solo nginx
docker compose logs -f nginx

# Solo backend
docker compose logs -f backend

# Solo PostgreSQL
docker compose logs -f db
```

### Verificar estado

```bash
# Ver servicios activos
docker compose ps

# Verificar health
curl https://tu-dominio.com/health
```

## Mantenimiento

### Actualizar

```bash
git pull
./stop.sh
./start.sh
```

### Backup de datos

```bash
# Backup de PostgreSQL
docker compose exec db pg_dump -U aquadetection aquadetection_db > backup.sql

# Restaurar
docker compose exec -T db psql -U aquadetection aquadetection_db < backup.sql
```

### Detener servicios

```bash
./stop.sh
```

## Troubleshooting

### El certificado falla en Let's Encrypt

**Causas comunes:**
- DNS no está correctamente apuntando a tu servidor
- Puerto 80 no está accesible
- Firewall bloqueando

**Solución:**
```bash
# Verificar DNS
nslookup tu-dominio.com

# Verificar conectividad en puerto 80
curl http://tu-dominio.com/.well-known/acme-challenge/test

# Ver logs de nginx
docker compose logs nginx | grep certbot
```

### Backend no puede conectar a BD

```bash
# Ver logs del backend
docker compose logs backend

# Reinicializar BD
docker compose exec backend python init_db.py
```

### Usuario/contraseña olvidados

```bash
# Reinicializar usuarios por defecto
docker compose exec backend python -c "
from app.models.user import User
from app.core.security import get_password_hash
from app.core.database import SessionLocal

db = SessionLocal()
user = db.query(User).filter(User.username == 'admin').first()
if user:
    user.hashed_password = get_password_hash('admin123')
    db.commit()
    print('Contraseña admin resetada a: admin123')
"
```

## Performance

Para mejorar rendimiento en producción:

### 1. Aumentar workers de Nginx

```bash
nano infrastructure/nginx/nginx.conf
# Cambiar: worker_processes auto;
```

### 2. Optimizar PostgreSQL

```bash
nano docker-compose.yml
# Agregar en db.environment:
# - POSTGRES_INIT_ARGS=-c max_connections=200
```

### 3. Habilitar caché

```bash
# Nginx ya tiene gzip activado
# Verifica en: infrastructure/nginx/nginx.conf
```

## Soporte

Para problemas o preguntas:

- Consulta los logs: `docker compose logs -f`
- Verifica health: `curl https://tu-dominio.com/health`
- Reinicia servicios: `./stop.sh && ./start.sh`

---

**Última actualización:** Enero 2026

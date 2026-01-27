# AcuaDetection - Guia Completa del Sistema

**Version**: 2.0 SSL/TLS Edition  
**Ultima Actualizacion**: 2025-01-26  
**Estado**: Production-Ready  

---

## Tabla de Contenidos

1. [Cambios Principales en v2.0](#cambios-principales-en-v20-sslhttps-migration)
2. [Stack de Tecnologias](#stack-de-tecnologias)
3. [Arquitectura del Sistema](#arquitectura-del-sistema)
4. [Requisitos e Instalacion](#requisitos-e-instalacion)
5. [Configuracion Inicial](#configuracion-inicial)
6. [Inicio del Sistema](#inicio-del-sistema)
7. [Gestion de Usuarios](#gestion-de-usuarios)
8. [Uso del Sistema](#uso-del-sistema)
9. [API REST Completa](#api-rest-completa)
10. [Seguridad Implementada](#seguridad-implementada)
11. [Deployment en la Nube](#deployment-en-la-nube)
12. [Solucion de Problemas](#solucion-de-problemas)
13. [Referencia Tecnica](#referencia-tecnica)

---

## Cambios Principales en v2.0 (SSL/HTTPS Migration)

**Antes (v1.0 - Localhost HTTP):**
-  Servicio expuesto en HTTP inseguro
-  Acceso publico en puertos 8082, 8083
-  Cualquiera podia acceder
-  No apto para produccion en la nube

**Ahora (v2.0 - Cloud-Ready HTTPS):**
-  SSL/TLS encryption (HTTPS)
-  Dominio personalizado: `aquadetection.local`
-  Control de acceso por IP: solo `10.3.11.101`
-  Certificados gestionados automaticamente con CertBot
-  HTTP/2 y compresion GZIP
-  Security Headers (HSTS, X-Frame-Options)
-  Reverse Proxy con Nginx
-  Ready para AWS, Azure, GCP

### Cambios en Puertos y Acceso

| Componente | v1.0 | v2.0 | Acceso |
|-----------|------|------|--------|
| **Frontend** | `localhost:8082` | `https://aquadetection.local:8443` | Solo IP 10.3.11.101 |
| **Backend API** | `localhost:8083` | `https://aquadetection.local:8443/api/v1` | Solo IP 10.3.11.101 |
| **BD PostgreSQL** | `localhost:5432` | `127.0.0.1:5434` | Solo local (Docker) |

### Caracteristicas Nuevas de Seguridad

```
SSL/TLS 1.3 con RSA 2048-bit
Certificados auto-renovables con CertBot
IP Whitelist enforcement
HTTP/2 protocol
GZIP compression
Security Headers
Audit Logging Completo
```

---

## Stack de Tecnologias

### Backend

| Tecnologia | Version | Proposito |
|-----------|---------|----------|
| **Python** | 3.11+ | Lenguaje principal |
| **FastAPI** | 0.104+ | Framework API asincronico |
| **Pydantic** | 2.0+ | Validacion de datos |
| **SQLAlchemy** | 2.0+ | ORM para base de datos |
| **Uvicorn** | 0.24+ | ASGI server |
| **JWT** | PyJWT 2.8+ | Autenticacion sin estado |
| **bcrypt** | 4.1+ | Hash de contrasenas |

### Frontend

| Tecnologia | Version | Proposito |
|-----------|---------|----------|
| **React** | 18+ | UI framework |
| **TypeScript** | 5+ | Type safety |
| **Vite** | 5+ | Build tool ultra-rapido |
| **Tailwind CSS** | 3+ | Styling utility-first |
| **Axios** | 1.6+ | HTTP client |
| **React Router** | 6+ | Routing |

### Infraestructura

| Tecnologia | Version | Proposito |
|-----------|---------|----------|
| **Docker** | 24+ | Containerizacion |
| **Docker Compose** | 2.20+ | Orchestracion |
| **Nginx** | 1.29-alpine | Reverse Proxy + SSL/TLS |
| **PostgreSQL** | 15-alpine | Base de datos relacional |
| **CertBot** | 2.0+ | SSL/TLS Certificate Management |
| **OpenSSL** | 3.0+ | Criptografia |

### Analisis de Amenazas (Integraciones)

| API | Proposito | Tipo |
|-----|----------|------|
| **VirusTotal** | Analisis de hashes y URLs | Malware Intelligence |
| **AbuseIPDB** | Reputacion de IPs | IP Intelligence |
| **URLhaus** | Bases de datos de URLs maliciosas | URL Intelligence |
| **YARA Rules** | Deteccion de patrones | Local Pattern Matching |
| **Sandbox Detections** | Comportamiento de malware | Behavioral Analysis |

---

## Arquitectura del Sistema

### Diagrama General

```
+-------------------------------------------------------------+
|                    Internet / Cloud                          |
+----------------------------+--------------------------------+
                             |
                    +----------------+
                    |  IP Whitelist   |
                    |  10.3.11.101    |
                    +--------+--------+
                             |
           +-----------------+------------------+
           |                                    |
     +-----------+                     +-----------+
     |   HTTPS    |                     |    HTTP    |
     |   Port 443 |                     |   Port 80  |
     +-----+------+                     +-----+------+
           |                                   |
           +---------------+-------------------+
                           |
                    +------------+
                    |    Nginx    |
                    |  SSL/TLS    |
                    |  Proxy      |
                    +------+------+
                           |
          +----------------+----------------+
          |                |                |
    +----------+   +----------+   +----------+
    | Frontend  |   |  Backend  |   | Database  |
    |  (React)  |   | (FastAPI) |   | (PostgreSQL)
    | Port 3000 |   | Port 8000 |   | Port 5432 |
    |(Internal) |   |(Internal) |   |(Internal) |
    +-----------+   +-----------+   +-----------+
```

### Flujo de Solicitud

```
1. Usuario accede a https://aquadetection.local
              
2. TLS Handshake (Certificate validation)
              
3. IP Whitelist Check (10.3.11.101)
              
4. Nginx recibe solicitud HTTPS
              
5. Request a Frontend (React) o Backend (API)
              
6. Backend consulta PostgreSQL si es necesario
              
7. Response con datos (JSON/HTML)
              
8. Nginx encripta con TLS 1.3
              
9. Cliente recibe datos seguros
```

### Componentes Principales

#### **Nginx (Reverse Proxy + SSL/TLS)**
- Termina conexiones TLS
- Redirige HTTP -> HTTPS
- Enruta trafico a Frontend/Backend
- Valida IP origen
- Anade security headers
- Comprime con GZIP

#### **Frontend (React + Vite)**
- SPA interactiva
- UI responsive con Tailwind
- Autenticacion con JWT
- Comunicacion con Backend via API

#### **Backend (FastAPI)**
- REST API asincronico
- Autenticacion y autorizacion
- Validacion de datos
- Integracion con APIs externas
- Analisis de amenazas

#### **PostgreSQL**
- Almacenamiento persistente
- Usuarios y roles
- Indices optimizados
- Backups automatizados

---

## Requisitos e Instalacion

### Requisitos del Sistema

```
 Sistema Operativo: Linux (Ubuntu 20.04+, Debian 11+)
 CPU: 2+ cores
 RAM: 4GB minimo (8GB recomendado)
 Disco: 10GB espacio libre
 Conexion de red: Estable
 Puertos a usar: 8080 (HTTP alias), 8443 (HTTPS), 5434 (PostgreSQL)
 IP del servidor: 10.3.11.101
```

### Software Requerido

```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y \
    docker.io \
    docker-compose \
    git \
    curl \
    openssl \
    python3 \
    python3-pip

# Verificar instalacion
docker --version
docker-compose --version
python3 --version
```

### Permisos de Docker

```bash
# Evitar necesidad de sudo
sudo usermod -aG docker $USER
newgrp docker

# Verificar
docker ps
```

### Clonar Repositorio

```bash
git clone https://github.com/tuorganizacion/aquadetection.git
cd aquadetection
chmod +x *.sh
```

---

## Configuracion Inicial

### 1. Crear Archivo `.env`

```bash
# Crear desde template
cp .env.example .env

# Editar configuracion
nano .env
```

### 2. Contenido del `.env` (Esencial)

```bash
# ========== SSL/TLS Configuration ==========
DOMAIN_NAME=aquadetection.local
CERT_TYPE=self-signed          # 'self-signed' o 'letsencrypt'
EMAIL=admin@aquadetection.local       # Para Let's Encrypt
ALLOWED_IP=10.3.11.101         # IP para whitelist

# ========== Database Configuration ==========
POSTGRES_DB=aquadetection_db
POSTGRES_USER=aquadetection_user
POSTGRES_PASSWORD=YourSecurePassword123!
DATABASE_URL=postgresql://aquadetection_user:YourSecurePassword123!@db:5432/aquadetection_db

# ========== Backend Configuration ==========
SECRET_KEY=your-secret-key-change-me-in-production-minimum-32-chars-long
ENVIRONMENT=production          # 'development' o 'production'
LOG_LEVEL=INFO

# ========== API Keys (Opcional pero recomendado) ==========
VIRUSTOTAL_API_KEY=your_virustotal_key_here
ABUSEIPDB_API_KEY=your_abuseipdb_key_here

# ========== Security ==========
CORS_ORIGINS=https://aquadetection.local
SESSION_TIMEOUT=3600          # segundos
```

### 3. Configurar `/etc/hosts`

En tu maquina local **Y** en el servidor (10.3.11.101):

```bash
sudo nano /etc/hosts

# Agregar estas lineas:
127.0.0.1       aquadetection.local
10.3.11.101     aquadetection.local
```

### 4. Verificar Configuracion

```bash
# Validar archivo .env
grep "DOMAIN_NAME\|ALLOWED_IP\|SECRET_KEY" .env

# Verificar que no hay espacios extras
cat .env | grep "=" | head -5

# Probar conectividad
ping -c 3 10.3.11.101
curl -I https://10.3.11.101 2>/dev/null || echo "Esperado: conexion rechazada (todavia no iniciado)"
```

---

## Inicio del Sistema

### Opcion 1: Inicio Rapido (Recomendado)

```bash
# Ir al directorio raiz
cd /ruta/a/aquadetection

# Iniciar todo
./start.sh

# Esperar 30-60 segundos para que se generen certificados
# Ver logs
docker-compose logs -f nginx

# Cuando veas: "nginx entered RUNNING state"
# El sistema esta listo
```

### Opcion 2: Inicio Manual con Docker Compose

```bash
# Construir imagenes (primera vez)
docker-compose build

# Iniciar servicios
docker-compose up -d

# Ver estado
docker-compose ps

# Ver logs
docker-compose logs -f
```

### Opcion 3: Inicio con Script SSL Personalizado

```bash
chmod +x setup_ssl.sh aquadetection_ssl.sh

# Configurar SSL
./setup_ssl.sh

# Iniciar servicios SSL
./aquadetection_ssl.sh start

# Ver estado
./aquadetection_ssl.sh status

# Probar HTTPS
./aquadetection_ssl.sh test-https
```

### Verificar que Todo Esta Funcionando

```bash
# Ver estado de servicios
docker-compose ps

# Deberia mostrar:
# NAME          STATUS
# nginx         Up (healthy)
# frontend      Up
# backend       Up
# db            Up

# Verificar logs de Nginx
docker-compose logs nginx | tail -20

# Probar certificado SSL
openssl s_client -connect 10.3.11.101:443 -servername aquadetection.local < /dev/null

# Deberia mostrar: "Verify return code: 18 (self signed certificate)"

# Probar acceso HTTPS
curl -k -I https://aquadetection.local/ 2>&1 | head -10

# Deberia mostrar: "HTTP/2 200"
```

### Inicializar Base de Datos (Primera Vez)

```bash
# Ejecutar script de inicializacion
docker-compose exec backend python init_db.py

# Resultado esperado:
#  Tables created successfully
#  Admin user created (admin/admin123)
#  Default user created (user/user123)
```

---

##  Gestion de Usuarios

### Credenciales por Defecto

| Usuario | Contrasena | Rol | Descripcion |
|---------|-----------|-----|-------------|
| `admin` | `admin123` | Admin | Acceso total al sistema |
| `user` | `user123` | User | Acceso limitado a scans |

 **CAMBIAR CONTRASENAS INMEDIATAMENTE DESPUES DEL PRIMER LOGIN**

### Opcion 1: Script Interactivo (Recomendado)

```bash
# Menu interactivo completo
./manage_users.sh

# Opciones:
# [1] Crear nuevo usuario
# [2] Listar todos los usuarios
# [3] Cambiar contrasena
# [4] Promover a administrador
# [5] Degradar de administrador
# [6] Eliminar usuario
# [7] Crear usuario rapido
```

### Opcion 2: Script de Linea de Comandos

```bash
# Crear usuario regular
./quick_user.sh analyst1 secure_password

# Crear usuario rapido (password = username)
./quick_user.sh analyst1

# Crear administrador
./quick_user.sh admin2 admin_pass admin
```

### Opcion 3: Linea de Comandos Directa

```bash
# Acceder a shell del backend
docker-compose exec backend bash

# Crear usuario via Python
python3 << 'EOF'
from app.core.database import SessionLocal
from app.models.user import User
from app.core.security import get_password_hash

db = SessionLocal()
try:
    new_user = User(
        username="analyst2",
        hashed_password=get_password_hash("password123"),
        is_admin=False
    )
    db.add(new_user)
    db.commit()
    print(" Usuario creado: analyst2")
finally:
    db.close()
EOF
```

### Gestion de Roles

```bash
# Promover usuario a admin
./manage_users.sh  # Opcion 4

# Degradar admin a usuario regular
./manage_users.sh  # Opcion 5

# Ver todos los usuarios y roles
./manage_users.sh  # Opcion 2
```

---

## Uso del Sistema

### Acceso a la Aplicacion

#### Via Dominio (Recomendado)

```
https://aquadetection.local
```

#### Via IP Directa

```
https://10.3.11.101
```

#### APIs de Backend

```
Documentacion Swagger: https://aquadetection.local/api/v1/docs
ReDoc: https://aquadetection.local/api/v1/redoc
OpenAPI JSON: https://aquadetection.local/api/v1/openapi.json
```

### Login

1. Abre https://aquadetection.local
2. Ingresa credenciales:
   - Usuario: `admin` o `user`
   - Contrasena: la contrasena asignada
3. Click en "Login"
4. Se generara JWT token valido por 1 hora

### Dashboard Principal

**Para Administradores:**
-  Dashboard de amenazas
-  Escaneo de IPs, Hashes, Dominios
-  Gestion de ransomware
-  Gestion de usuarios
-  Logs de auditoria
-  Configuracion del sistema

**Para Usuarios Regulares:**
-  Dashboard simplificado
-  Escaneo de amenazas
-  Historial de analisis

### Escaneo de Amenazas

#### Analisis de Hash MD5/SHA256

```
1. Ir a "Security Engine" -> "Scan"
2. Seleccionar tipo: "File Hash"
3. Pegar hash: e.g., d41d8cd98f00b204e9800998ecf8427e
4. Click "Analyze"
5. Resultados de VirusTotal, URLhaus, etc.
```

#### Analisis de IP

```
1. Ir a "Security Engine" -> "Scan"
2. Seleccionar tipo: "IP Address"
3. Ingresar IP: e.g., 192.168.1.1
4. Click "Analyze"
5. Resultados de reputacion de AbuseIPDB
```

#### Analisis de Dominio/URL

```
1. Ir a "Security Engine" -> "Scan"
2. Seleccionar tipo: "URL"
3. Ingresar URL: e.g., https://example.com
4. Click "Analyze"
5. Resultados de VirusTotal y URLhaus
```

### Gestion de Ransomware

**Solo para Administradores:**

```
1. Ir a "Ransomware Manager"
2. Opciones:
   -  Agregar nuevo IOC
   -  Buscar IOCs existentes
   -  Ver estadisticas
   -  Eliminar IOC
```

### Ver Logs de Auditoria

**Solo para Administradores:**

```
1. Ir a "System Logs"
2. Filtrar por:
   - Usuario
   - Tipo de accion
   - Fecha
   - Resultado (exitoso/fallido)
3. Ver detalles completos de cada accion
```

---

##  API REST Completa

### Autenticacion

#### Obtener Token JWT

```bash
curl -X POST "https://aquadetection.local/api/v1/auth/login/access-token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123" \
  -k  # Ignorar certificado autofirmado
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

#### Usar Token en Solicitudes

```bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -X GET "https://aquadetection.local/api/v1/users/me" \
  -H "Authorization: Bearer $TOKEN" \
  -k
```

### Endpoints de Escaneo

#### Escanear Hash (VirusTotal)

```bash
curl -X POST "https://aquadetection.local/api/v1/scan/hash" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"file_hash": "d41d8cd98f00b204e9800998ecf8427e"}' \
  -k
```

**Response:**
```json
{
  "hash": "d41d8cd98f00b204e9800998ecf8427e",
  "results": {
    "virustotal": {
      "detected": false,
      "detections": 0,
      "total": 70
    }
  }
}
```

#### Escanear IP (AbuseIPDB)

```bash
curl -X POST "https://aquadetection.local/api/v1/scan/ip" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ip_address": "192.168.1.1"}' \
  -k
```

#### Escanear URL

```bash
curl -X POST "https://aquadetection.local/api/v1/scan/url" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}' \
  -k
```

### Endpoints de Usuarios (Admin)

#### Listar Usuarios

```bash
curl -X GET "https://aquadetection.local/api/v1/users/" \
  -H "Authorization: Bearer $TOKEN" \
  -k
```

#### Crear Usuario

```bash
curl -X POST "https://aquadetection.local/api/v1/users/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "analyst3",
    "password": "secure_pass",
    "is_admin": false
  }' \
  -k
```

#### Eliminar Usuario

```bash
curl -X DELETE "https://aquadetection.local/api/v1/users/5" \
  -H "Authorization: Bearer $TOKEN" \
  -k
```

### Endpoints de Ransomware (Admin)

#### Agregar IOC

```bash
curl -X POST "https://aquadetection.local/api/v1/ransomware/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "ioc_type": "hash",
    "ioc_value": "abc123def456",
    "threat_name": "Conti",
    "description": "Known Conti ransomware hash"
  }' \
  -k
```

#### Buscar IOCs

```bash
curl -X GET "https://aquadetection.local/api/v1/ransomware/searchquery=hash" \
  -H "Authorization: Bearer $TOKEN" \
  -k
```

### Documentacion Interactiva

```
Swagger UI: https://aquadetection.local/api/v1/docs
ReDoc:      https://aquadetection.local/api/v1/redoc
```

---

## Seguridad Implementada

### 1. Autenticacion

```
 JWT (JSON Web Tokens) con RS256
 Contrasenas hasheadas con bcrypt (rounds=12)
 Token expiration: 1 hora
 Refresh token capability
 Logout / token invalidation
```

### 2. Autorizacion (RBAC)

```
 Dos roles: Admin y User
 Endpoints protegidos por rol
 Acceso granular a funciones
 Admin: Acceso total (usuarios, logs, configuracion)
 User: Solo scans de amenazas
```

### 3. Encriptacion TLS/SSL

```
 TLS 1.3 (y TLS 1.2 como fallback)
 RSA 2048-bit certificates
 Cipher suite: TLS_AES_256_GCM_SHA384
 Perfect Forward Secrecy (PFS)
 Staple OCSP
 HTTP/2 over TLS (h2)
```

### 4. Control de Acceso por Red

```
 IP Whitelist: Solo 10.3.11.101
 Implementado a nivel Nginx (geo block)
 Logs de intentos rechazados
 DDoS protection (rate limiting)
```

### 5. Security Headers

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Frame-Options: DENY                    # Evitar clickjacking
X-Content-Type-Options: nosniff          # Evitar MIME sniffing
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: default-src 'self'
```

### 6. Auditoria y Logging

```
 Log de todos los logins (exitosos y fallidos)
 Log de cambios de usuarios
 Log de acciones administrativas
 Log de analisis/escaneos
 Timestamps y IP de origen
 Nivel de severidad (INFO, WARNING, ERROR)
 Logs no modificables (append-only)
```

### 7. Validacion de Datos

```
 Pydantic models para type checking
 Input sanitization
 SQL injection prevention (ORM + parameterized queries)
 XSS prevention (React + sanitization)
 CSRF token validation
```

### 8. Gestion de Certificados

```
 Certificados autofirmados para dev (RSA 2048, 1 ano)
 CertBot para Let's Encrypt en produccion
 Auto-renovacion cada 60 dias
 Rollback automatico en fallo de renovacion
 Notificaciones de proximo vencimiento
```

### 9. Base de Datos

```
 PostgreSQL 15 con encriptacion
 Conexiones solo desde Backend (no expuesta)
 Puerto: 5434 (no estandar)
 Usuario especifico con permisos limitados
 Backups automaticos
```

### 10. Buenas Practicas

```
 Variables sensibles en .env (no en codigo)
 No logging de passwords
 Rate limiting en endpoints criticos
 CORS restrictivo (solo aquadetection.local)
 Secrets no versionados en Git
 Principio de minimo privilegio
```

---

##  Deployment en la Nube

### Preparacion para Produccion

Antes de deployar, asegurate de:

```bash
# 1. Cambiar todas las contrasenas por defecto
nano .env
# Editar: POSTGRES_PASSWORD, SECRET_KEY, admin password

# 2. Configurar HTTPS con Let's Encrypt (no autofirmado)
CERT_TYPE=letsencrypt
EMAIL=your-email@yourdomain.com
DOMAIN_NAME=aquadetection.yourdomain.com

# 3. Actualizar IP whitelist
ALLOWED_IP=your.cloud.server.ip

# 4. Habilitar backups
docker-compose exec db pg_dump -U aquadetection_user aquadetection_db > backup.sql

# 5. Configurar alertas y monitoreo
# Ver seccion "Monitoreo"
```

### Opcion 1: AWS EC2

```bash
# 1. Crear instancia EC2
# - Ubuntu 22.04 LTS
# - t3.medium (2 vCPU, 4GB RAM)
# - Security Group: 80, 443, 22 (SSH)
# - Asignar Elastic IP

# 2. SSH a instancia
ssh -i key.pem ubuntu@your-ec2-ip

# 3. Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# 4. Clonar repositorio
git clone https://github.com/tuorganizacion/aquadetection.git
cd aquadetection

# 5. Configurar .env para AWS
cp .env.example .env
nano .env
# Editar: DOMAIN_NAME, ALLOWED_IP, credenciales, etc.

# 6. Usar Let's Encrypt (no autofirmado)
sed -i 's/CERT_TYPE=.*/CERT_TYPE=letsencrypt/' .env

# 7. Iniciar
docker-compose up -d

# 8. Verificar
docker-compose ps
docker-compose logs nginx | tail -50

# 9. Configurar DNS (Route 53)
# Apuntar tu dominio al Elastic IP de AWS
```

### Opcion 2: Azure Container Instances

```bash
# 1. Crear container group
az container create \
  --resource-group myResourceGroup \
  --name aquadetection \
  --image nginx:latest \
  --ports 80 443 \
  --environment-variables \
    DOMAIN_NAME=aquadetection.yourdomain.com \
    ALLOWED_IP=your.ip.address

# 2. Configurar DNS
# Apuntar dominio a la IP de Azure
```

### Opcion 3: GCP Compute Engine

```bash
# 1. Crear instancia
gcloud compute instances create aquadetection \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=e2-medium

# 2. Configurar firewall
gcloud compute firewall-rules create allow-https \
  --allow=tcp:443,tcp:80,tcp:22

# 3. SSH
gcloud compute ssh aquadetection

# 4. Instalar y configurar (igual a AWS)
```

### Configuracion de Dominio

#### Con Let's Encrypt (Recomendado)

```bash
# El CertBot se configura automaticamente en docker-compose.yml

# 1. Asegurar que el dominio esta configurado en DNS
# 2. Asegurar que puertos 80 y 443 estan abiertos
# 3. En .env:
CERT_TYPE=letsencrypt
EMAIL=your-email@yourdomain.com
DOMAIN_NAME=aquadetection.yourdomain.com

# 4. Iniciar (CertBot generara certificados automaticamente)
docker-compose up -d

# 5. Verificar certificados
docker-compose logs certbot | tail -20

# 6. Los certificados se renuevan automaticamente
# Verificar proxima renovacion
docker-compose exec nginx certbot renew --dry-run
```

#### Renovacion de Certificados

```bash
# Manual
docker-compose exec nginx certbot renew

# Automatico (cron job, ejecutado cada dia)
# Ya incluido en docker-compose.yml

# Verificar
docker-compose logs nginx | grep certbot
```

### Backups y Recuperacion

```bash
# 1. Backup de base de datos
docker-compose exec db pg_dump -U aquadetection_user aquadetection_db > aquadetection_backup_$(date +%Y%m%d).sql

# 2. Backup de configuracion
tar -czf aquadetection_config_$(date +%Y%m%d).tar.gz .env infrastructure/

# 3. Copiar a almacenamiento seguro (S3, Azure Blob, etc.)
aws s3 cp aquadetection_backup_*.sql s3://my-bucket/backups/

# 4. Restaurar desde backup
docker-compose exec -T db psql -U aquadetection_user aquadetection_db < aquadetection_backup_20250126.sql
```

### Monitoreo y Alertas

```bash
# Ver logs en tiempo real
docker-compose logs -f

# Ver logs especificos
docker-compose logs nginx
docker-compose logs backend
docker-compose logs db

# Usar herramientas de monitoreo
# - CloudWatch (AWS)
# - Azure Monitor (Azure)
# - Cloud Logging (GCP)

# Alertas recomendadas:
# - Certificado a punto de vencer (Let's Encrypt)
# - Fallo de servicio
# - Alto uso de CPU/memoria
# - Errores en logs del backend
```

---

##  Solucion de Problemas

### Problema 1: "SSL Certificate Error"

**Sintoma:** Browser muestra "Your connection is not private"

**Causa Probable:** Certificado autofirmado en desarrollo

**Solucion:**

```bash
# Opcion 1: Ignorar advertencia
# Avanzado -> Ir a aquadetection.local (inseguro)

# Opcion 2: Importar certificado como confiable
docker-compose exec nginx cat /etc/letsencrypt/live/aquadetection.local/cert.pem > aquadetection.pem

# En macOS:
open aquadetection.pem
# Keychain Access -> Always Trust

# En Linux:
sudo cp aquadetection.pem /usr/local/share/ca-certificates/
sudo update-ca-certificates

# En Windows:
# Settings -> Certificates -> Import -> Trusted Root
```

### Problema 2: "Connection Refused" / No se puede acceder

**Sintoma:** `curl: (7) Failed to connect to aquadetection.local port 443`

**Verificar:**

```bash
# 1. Docker esta corriendo
docker-compose ps

# 2. Nginx esta UP
docker-compose logs nginx | tail -20

# 3. Puerto 443 esta disponible
sudo lsof -i :443

# 4. Dominio esta en /etc/hosts
cat /etc/hosts | grep aquadetection

# 5. Firewall esta permitiendo 443
sudo ufw allow 443
```

**Solucion:**

```bash
# Reiniciar Nginx
docker-compose restart nginx

# Verificar configuracion Nginx
docker-compose exec nginx nginx -t

# Ver logs
docker-compose logs nginx
```

### Problema 3: "IP Address Not Allowed"

**Sintoma:** `403 Forbidden` error

**Causa:** IP no esta en whitelist

**Solucion:**

```bash
# 1. Verificar tu IP actual
curl ifconfig.me

# 2. Actualizar .env con tu IP
ALLOWED_IP=your.actual.ip.here

# 3. Verificar nginx.conf
docker-compose exec nginx cat /etc/nginx/nginx.conf | grep -A 5 "geo"

# 4. Recargar Nginx
docker-compose exec nginx nginx -s reload

# Alternativa: Deshabilitar whitelist temporalmente (SOLO desarrollo)
# Comentar linea "deny all" en nginx.conf
```

### Problema 4: Database Connection Error

**Sintoma:** Backend no puede conectar a PostgreSQL

**Solucion:**

```bash
# 1. Verificar PostgreSQL esta corriendo
docker-compose ps db

# 2. Verificar credenciales en .env
grep DATABASE_URL .env

# 3. Conectar directamente a BD
docker-compose exec db psql -U aquadetection_user -d aquadetection_db

# 4. Ver logs de BD
docker-compose logs db

# 5. Reiniciar BD
docker-compose restart db
```

### Problema 5: "Out of Memory"

**Sintoma:** Docker containers se detienen sin razon

**Solucion:**

```bash
# Ver consumo de memoria
docker stats

# Reducir limites en docker-compose.yml
# Agregar:
# services:
#   backend:
#     mem_limit: 1024m
#   frontend:
#     mem_limit: 512m

# Reiniciar
docker-compose up -d
```

### Problema 6: Frontend No Carga

**Sintoma:** Pagina en blanco o "Cannot GET /"

**Solucion:**

```bash
# 1. Verificar frontend esta corriendo
docker-compose ps frontend

# 2. Ver logs del frontend
docker-compose logs frontend

# 3. Verificar puerto 3000
docker-compose exec frontend curl localhost:3000

# 4. Verificar configuracion Nginx
docker-compose exec nginx cat /etc/nginx/conf.d/default.conf | grep -A 10 "location /"

# 5. Reconstruir frontend
docker-compose build frontend
docker-compose up -d frontend
```

### Problema 7: API Retorna 401/403

**Sintoma:** "Unauthorized" o "Forbidden"

**Verificar:**

```bash
# 1. Token valido
curl -X POST "https://aquadetection.local/api/v1/auth/login/access-token" \
  -d "username=admin&password=admin123" \
  -k

# 2. Token incluido en request
curl -X GET "https://aquadetection.local/api/v1/users/me" \
  -H "Authorization: Bearer $TOKEN" \
  -k

# 3. Token expirado
# Token valido por 1 hora
# Obtener nuevo token

# 4. Usuario existe
./manage_users.sh  # Ver opcion 2
```

### Problema 8: Certificado Proximo a Vencer

**Sintoma:** Advertencia en logs sobre certificado vencido

**Solucion:**

```bash
# 1. Renovar manualmente
docker-compose exec nginx certbot renew

# 2. Ver proxima renovacion
docker-compose exec nginx certbot certificates

# 3. Para Let's Encrypt:
# Se renueva automaticamente 30 dias antes de vencer

# 4. Configurar alertas
# Agregar a crontab:
# 0 0 * * * certbot renew --email admin@yourdomain.com
```

### Problema 9: Rendimiento Lento

**Sintoma:** Respuestas lentas desde la API

**Optimizaciones:**

```bash
# 1. Verificar recursos disponibles
docker stats

# 2. Ver logs del backend
docker-compose logs backend | grep ERROR

# 3. Aumentar workers Uvicorn
# En backend/main.py:
# uvicorn.run(..., workers=4)

# 4. Aumentar pool de conexiones PostgreSQL
# En docker-compose.yml env
SQLALCHEMY_POOL_SIZE=20
SQLALCHEMY_MAX_OVERFLOW=40

# 5. Cachear respuestas en Nginx
# nginx.conf:
# proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=api_cache:10m;

# 6. Habilitar compresion GZIP
# Ya habilitado en nginx.conf
# Verificar:
curl -I -H "Accept-Encoding: gzip" https://aquadetection.local/
# Deberia mostrar: Content-Encoding: gzip
```

---

##  Referencia Tecnica

### Estructura de Carpetas

```
aquadetection/
+-- backend/
|   +-- app/
|   |   +-- api/           # Endpoints REST
|   |   |   +-- auth.py
|   |   |   +-- logs.py
|   |   |   +-- ransomware.py
|   |   |   +-- scan.py
|   |   |   +-- users.py
|   |   +-- core/          # Configuracion core
|   |   |   +-- config.py
|   |   |   +-- database.py
|   |   |   +-- encryption.py
|   |   |   +-- logging.py
|   |   |   +-- security.py
|   |   +-- models/        # Modelos de BD
|   |   |   +-- user.py
|   |   |   +-- ransomware.py
|   |   |   +-- audit_log.py
|   |   +-- services/      # Logica de negocio
|   |       +-- scan_service.py
|   |       +-- audit.py
|   +-- main.py            # Punto de entrada
|   +-- init_db.py         # Inicializacion BD
|   +-- Dockerfile         # Build backend
|   +-- requirements.txt    # Dependencias Python
|
+-- frontend/
|   +-- src/
|   |   +-- components/    # Componentes React
|   |   |   +-- admin/
|   |   |   +-- auth/
|   |   |   +-- common/
|   |   |   +-- dashboard/
|   |   +-- services/      # Servicios HTTP
|   |   |   +-- api.ts
|   |   +-- context/       # Context API
|   |   |   +-- AuthContext.tsx
|   |   +-- App.tsx        # Root component
|   |   +-- main.tsx       # Entry point
|   +-- Dockerfile         # Build frontend
|   +-- package.json       # Dependencias npm
|   +-- vite.config.ts     # Configuracion Vite
|   +-- tailwind.config.js # Configuracion Tailwind
|
+-- infrastructure/
|   +-- nginx/
|       +-- Dockerfile     # Build Nginx personalizado
|       +-- nginx.conf     # Configuracion Nginx
|       +-- init_certbot.sh # Script inicializacion certificados
|       +-- renew_certs.sh # Script renovacion certificados
|
+-- docker-compose.yml     # Orquestacion servicios
+-- .env.example          # Template .env
+-- setup_ssl.sh          # Setup inicial SSL
+-- aquadetection_ssl.sh         # Comandos SSL
+-- start.sh              # Iniciar sistema
+-- stop.sh               # Detener sistema
+-- manage_users.sh       # Gestion usuarios interactivo
+-- quick_user.sh         # Crear usuario rapido
+-- README.md             # Este archivo
```

### Puertos en Uso

| Puerto | Servicio | Protocolo | Acceso | Descripcion |
|--------|----------|-----------|--------|-------------|
| **8080** | Nginx | HTTP | Externo | Redireccion a HTTPS (alias para puerto 80) |
| **8443** | Nginx | HTTPS | Externo (10.3.11.101) | Reverse proxy (alias para puerto 443) |
| **3000** | Frontend | HTTP | Interno | React (solo Docker) |
| **8000** | Backend | HTTP | Interno | FastAPI (solo Docker) |
| **5434** | PostgreSQL | TCP | Interno | Base de datos |

### Certificados SSL/TLS

```
Ubicacion en Docker: /etc/letsencrypt/live/aquadetection.local/
+-- fullchain.pem  # Certificado + cadena
+-- privkey.pem    # Clave privada
+-- cert.pem       # Certificado
+-- chain.pem      # Cadena de autoridad

Volumen Docker: certbot_data
Renovacion automatica: Cada 60 dias (Let's Encrypt)
Algoritmo: RSA 2048-bit
Protocolo: TLS 1.2, TLS 1.3
```

### Variables de Entorno Esenciales

```bash
# SSL/TLS
DOMAIN_NAME              # Dominio del sistema
CERT_TYPE               # 'self-signed' o 'letsencrypt'
EMAIL                   # Email para Let's Encrypt
ALLOWED_IP              # IP whitelist

# Base de Datos
POSTGRES_USER           # Usuario PostgreSQL
POSTGRES_PASSWORD       # Contrasena PostgreSQL
POSTGRES_DB             # Nombre base de datos
DATABASE_URL            # URL conexion completa

# Backend
SECRET_KEY              # Clave para JWT (min 32 chars)
ENVIRONMENT             # 'development' o 'production'
LOG_LEVEL              # DEBUG, INFO, WARNING, ERROR

# APIs Externas
VIRUSTOTAL_API_KEY      # API key VirusTotal
ABUSEIPDB_API_KEY       # API key AbuseIPDB

# CORS
CORS_ORIGINS            # Origenes permitidos
SESSION_TIMEOUT         # Timeout sesion (segundos)
```

### Comandos Docker Utiles

```bash
# Ver logs en tiempo real
docker-compose logs -f [servicio]

# Ejecutar comando en contenedor
docker-compose exec [servicio] [comando]

# Reiniciar servicio
docker-compose restart [servicio]

# Reconstruir imagen
docker-compose build [servicio]

# Ver consumo recursos
docker stats

# Copiar archivo de contenedor
docker-compose cp [servicio]:/ruta/archivo ./local/

# Ver volumenes
docker volume ls
docker volume inspect aquadetection_certbot_data

# Limpiar todo
docker-compose down -v
```

### Scripts Disponibles

| Script | Proposito | Uso |
|--------|----------|-----|
| `start.sh` | Iniciar sistema | `./start.sh` |
| `stop.sh` | Detener sistema | `./stop.sh` |
| `setup_ssl.sh` | Configuracion SSL inicial | `./setup_ssl.sh` |
| `aquadetection_ssl.sh` | Comandos SSL/gestion | `./aquadetection_ssl.sh [comando]` |
| `manage_users.sh` | Gestion usuarios interactivo | `./manage_users.sh` |
| `quick_user.sh` | Crear usuario rapido | `./quick_user.sh [user] [pass] [admin]` |

### Troubleshooting Avanzado

#### Verificar Certificado SSL

```bash
# Ver detalles del certificado
openssl x509 -in /path/to/cert.pem -text -noout

# Verificar certificado esta en servidor
openssl s_client -connect aquadetection.local:443 -servername aquadetection.local

# Validar cadena de certificados
openssl verify -CAfile /path/to/chain.pem cert.pem

# Ver proxima fecha de vencimiento
openssl x509 -enddate -noout -in cert.pem
```

#### Verificar Configuracion Nginx

```bash
# Validar sintaxis
docker-compose exec nginx nginx -t

# Ver configuracion cargada
docker-compose exec nginx nginx -T

# Ver puertos escuchando
docker-compose exec nginx netstat -tuln | grep LISTEN
```

#### Verificar Conectividad Base de Datos

```bash
# Conectar a PostgreSQL
docker-compose exec db psql -U aquadetection_user -d aquadetection_db

# Listar tablas
\dt

# Ver conexiones activas
SELECT * FROM pg_stat_activity;

# Salir
\q
```

#### Ver Variables de Entorno en Contenedor

```bash
docker-compose exec [servicio] env | sort
```

---

##  Soporte y Contacto

### Documentacion Interna

- **API Docs Swagger:** https://aquadetection.local/api/v1/docs
- **ReDoc:** https://aquadetection.local/api/v1/redoc
- **OpenAPI JSON:** https://aquadetection.local/api/v1/openapi.json

### Logs y Debugging

```bash
# Logs centralizados
docker-compose logs -f

# Por servicio
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f nginx
docker-compose logs -f db

# Estadisticas
docker stats
```

### Reporte de Problemas

Incluir:
1. Output de `docker-compose ps`
2. Output de `docker-compose logs [servicio]`
3. Logs de navegador (F12)
4. Comando exacto que causa el problema
5. Output esperado vs real

---

##  Changelog

### v2.0 (SSL/HTTPS Migration) - 2025-01-26

**Nuevas Caracteristicas:**
-  HTTPS/TLS 1.3 encryption
-  Certificados SSL con CertBot
-  IP Whitelist (10.3.11.101)
-  Nginx reverse proxy
-  Security headers
-  HTTP/2 protocol
-  GZIP compression
-  Audit logging completo
-  Cloud deployment ready (AWS, Azure, GCP)

**Cambios Tecnicos:**
- Migracion de localhost a dominio `aquadetection.local`
- Puertos: 8082/8083 -> 80/443 (Nginx)
- Docker Compose v2 restructure
- .env obligatorio para configuracion
- Scripts de gestion mejorados

**Deprecaciones:**
- HTTP inseguro (localhost)
- Puertos 8082/8083

### v1.0 (Initial Release)

- Infraestructura base con Docker
- FastAPI backend
- React frontend
- PostgreSQL database
- JWT authentication
- Escaneo de amenazas
- Gestion de ransomware
- Logs de auditoria

---

**Hecho con  para seguridad en la nube**

**Ultima Actualizacion:** 26 de enero de 2025

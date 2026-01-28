# AcuaDetection - Sistema Completo de Detección de Amenazas

**Nota**: Este README contiene toda la documentación del proyecto consolidada en un único archivo.

**Versión**: 2.0 SSL/TLS Edition  
**Última Actualización**: Enero 2026  
**Estado**: Production-Ready  

Para iniciar el sistema, ejecute `./start.sh` y acceda a https://10.3.11.101:8443

---

## Información Importante

Antes de iniciar, considere lo siguiente:

1. **Certificados autofirmados**: El navegador mostrará una advertencia de conexión no segura. Esto es normal en redes privadas. Seleccione "Aceptar riesgo" para continuar.

2. **Credenciales de desarrollo**: Las credenciales por defecto (`admin/admin123`) son para desarrollo. Cambie estas credenciales en producción.

3. **Acceso local solamente**: El sistema está configurado para red privada (10.3.11.0/24). No exponga a internet sin configuración adicional de seguridad.

4. **Copias de seguridad regulares**: Realice copias de seguridad regulares de PostgreSQL:
   ```bash
   docker compose exec db pg_dump -U aquadetection aquadetection_db > backup.sql
   ```

---

## Tabla de Contenidos

1. [Inicio Rápido](#inicio-rápido)
2. [Cambios en v2.0 y Checklist](#cambios-principales-en-v20-sslhttps-migration-y-deployment-checklist)
3. [Stack de Tecnologías](#stack-de-tecnologías)
4. [Arquitectura del Sistema](#arquitectura-del-sistema)
5. [Requisitos e Instalación](#requisitos-e-instalación)
6. [Configuración Inicial](#configuración-inicial)
7. [Inicio del Sistema](#inicio-del-sistema)
8. [Gestión de Usuarios](#gestión-de-usuarios)
9. [Uso del Sistema](#uso-del-sistema)
10. [API REST](#api-rest-completa)
11. [Seguridad Implementada](#seguridad-implementada)
12. [Implementación en la Nube](#implementación-en-la-nube)
13. [Solución de Problemas](#solución-de-problemas)
14. [Referencia Técnica](#referencia-técnica)
15. [Soporte y Contacto](#soporte-y-contacto)

---

## Inicio Rápido

### Para Red Privada Local (10.3.11.101)

```bash
# 1. Navegar al directorio
cd /home/nicolasmolina-diaz/new

# 2. Ejecutar script de inicio
chmod +x start.sh
./start.sh

# El sistema estará disponible en 2-3 minutos
```

**Acceso después de iniciarse:**
- **UI**: https://10.3.11.101:8443
- **Documentación API**: https://10.3.11.101:8443/api/v1/docs
- **Base de API**: https://10.3.11.101:8443/api/v1
- **Usuario**: `admin` / Contraseña: `admin123`

**Comandos útiles durante la ejecución:**
```bash
Verificar:    ./verify_deployment.sh
Ver estado:   docker compose ps
Ver registros: docker compose logs -f
Detener:      ./stop.sh
```

### Para Producción con Dominio Personalizado

```bash
# 1. Apuntar DNS a su servidor
# En su proveedor DNS: A  su-dominio.com  →  SU_IP_SERVIDOR

# 2. Ejecutar inicio
./start.sh
# Se le solicitará: dominio y correo electrónico para Let's Encrypt

# 3. Acceso
https://su-dominio.com
```

### Estado de Configuración

El sistema se encuentra completamente configurado:
- Puertos: 8080 (HTTP) → 8443 (HTTPS)
- Certificados: Autofirmados (10 años)
- Base de datos: PostgreSQL 15-alpine
- Backend: FastAPI con endpoint /health
- Frontend: React + Tailwind CSS
- Nginx: Reverse proxy con SSL/TLS
- Inicialización: Automática
- Verificaciones de salud: Todos los servicios

---

## Cambios Principales en v2.0 (SSL/HTTPS Migration) y Checklist de Implementación

### Checklist Pre-Implementación

**Requisitos del Sistema:**
- [ ] Linux (Ubuntu 20.04+, Debian 11+)
- [ ] Docker CE 20.10+ instalado
- [ ] Docker Compose 2.0+ instalado
- [ ] CPU: 2+ núcleos
- [ ] RAM: 4GB mínimo (8GB recomendado)
- [ ] Disco: 10GB espacio libre
- [ ] Puertos 8080 y 8443 disponibles
- [ ] Acceso root/sudo

**Verificación Pre-Inicio:**
```bash
# Verificar Docker
docker --version
docker compose --version

# Verificar puertos disponibles
lsof -i :8080 || echo "Puerto 8080 disponible"
lsof -i :8443 || echo "Puerto 8443 disponible"

# Verificar espacio en disco
df -h | grep -E "/$|/home"

# Permisos ejecutables
chmod +x start.sh stop.sh
ls -la *.sh | grep rwx
```

### Cambios Principales en v2.0

**Antes (v1.0 - Localhost HTTP):**
- Servicio expuesto en HTTP inseguro
- Acceso público en puertos 8082, 8083
- Cualquiera podía acceder
- No apto para producción en la nube

**Ahora (v2.0 - Cloud-Ready HTTPS):**
- Encriptación SSL/TLS (HTTPS)
- Dominio personalizado: `aquadetection.local`
- Control de acceso por IP: solo `10.3.11.101`
- Certificados gestionados automáticamente con CertBot
- HTTP/2 y compresión GZIP
- Encabezados de seguridad (HSTS, X-Frame-Options)
- Reverse Proxy con Nginx
- Listo para AWS, Azure, GCP

### Cambios en Puertos y Acceso

| Componente | v1.0 | v2.0 | Acceso |
|-----------|------|------|--------|
| **Frontend** | `localhost:8082` | `https://aquadetection.local:8443` | Solo IP 10.3.11.101 |
| **Backend API** | `localhost:8083` | `https://aquadetection.local:8443/api/v1` | Solo IP 10.3.11.101 |
| **BD PostgreSQL** | `localhost:5432` | `127.0.0.1:5434` | Solo local (Docker) |

### Características Nuevas de Seguridad

```
SSL/TLS 1.3 con RSA 2048-bit
Certificados auto-renovables con CertBot
Aplicación de IP Whitelist
Protocolo HTTP/2
Compresión GZIP
Encabezados de Seguridad
Registro de Auditoría Completo
```

---

## Stack de Tecnologías

### Backend

| Tecnología | Versión | Propósito |
|-----------|---------|----------|
| **Python** | 3.11+ | Lenguaje principal |
| **FastAPI** | 0.104+ | Framework API asincrónico |
| **Pydantic** | 2.0+ | Validación de datos |
| **SQLAlchemy** | 2.0+ | ORM para base de datos |
| **Uvicorn** | 0.24+ | Servidor ASGI |
| **JWT** | PyJWT 2.8+ | Autenticación sin estado |
| **bcrypt** | 4.1+ | Hash de contraseñas |

### Frontend

| Tecnología | Versión | Propósito |
|-----------|---------|----------|
| **React** | 18+ | Framework de interfaz |
| **TypeScript** | 5+ | Seguridad de tipos |
| **Vite** | 5+ | Herramienta de construcción ultra-rápida |
| **Tailwind CSS** | 3+ | Estilos utility-first |
| **Axios** | 1.6+ | Cliente HTTP |
| **React Router** | 6+ | Enrutamiento |

### Infraestructura

| Tecnología | Versión | Propósito |
|-----------|---------|----------|
| **Docker** | 24+ | Containerización |
| **Docker Compose** | 2.20+ | Orquestación |
| **Nginx** | 1.29-alpine | Reverse Proxy + SSL/TLS |
| **PostgreSQL** | 15-alpine | Base de datos relacional |
| **CertBot** | 2.0+ | Gestión de Certificados SSL/TLS |
| **OpenSSL** | 3.0+ | Criptografía |

### Análisis de Amenazas (Integraciones)

| API | Propósito | Tipo |
|-----|----------|------|
| **VirusTotal** | Análisis de hashes y URLs | Inteligencia de Malware |
| **AbuseIPDB** | Reputación de IPs | Inteligencia de IP |
| **URLhaus** | Bases de datos de URLs maliciosas | Inteligencia de URL |
| **Reglas YARA** | Detección de patrones | Análisis de Patrones Local |
| **Detecciones de Sandbox** | Comportamiento de malware | Análisis Conductual |

---

## Arquitectura del Sistema

### Diagrama General

```
+-------------------------------------------------------------+
|                    Internet / Nube                           |
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
     |   Puerto 443 |                     |   Puerto 80  |
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
    | Frontend  |   |  Backend  |   | Base de datos  |
    |  (React)  |   | (FastAPI) |   | (PostgreSQL)
    | Puerto 3000 |   | Puerto 8000 |   | Puerto 5432 |
    |(Interno) |   |(Interno) |   |(Interno) |
    +-----------+   +-----------+   +-----------+
```

### Flujo de Solicitud

```
1. Usuario accede a https://aquadetection.local
              
2. Protocolo de enlace TLS (validación de certificado)
              
3. Verificación de IP Whitelist (10.3.11.101)
              
4. Nginx recibe solicitud HTTPS
              
5. Solicitud a Frontend (React) o Backend (API)
              
6. Backend consulta PostgreSQL si es necesario
              
7. Respuesta con datos (JSON/HTML)
              
8. Nginx encripta con TLS 1.3
              
9. Cliente recibe datos seguros
```

### Componentes Principales

#### **Nginx (Reverse Proxy + SSL/TLS)**
- Termina conexiones TLS
- Redirige HTTP -> HTTPS
- Enruta tráfico a Frontend/Backend
- Valida IP de origen
- Añade encabezados de seguridad
- Comprime con GZIP

#### **Frontend (React + Vite)**
- Aplicación de una sola página interactiva
- Interfaz receptiva con Tailwind
- Autenticación con JWT
- Comunicación con Backend vía API

#### **Backend (FastAPI)**
- API REST asincrónica
- Autenticación y autorización
- Validación de datos
- Integración con APIs externas
- Análisis de amenazas

#### **PostgreSQL**
- Almacenamiento persistente
- Usuarios y roles
- Índices optimizados
- Copias de seguridad automatizadas

---

## Requisitos e Instalación

### Requisitos del Sistema

```
 Sistema Operativo: Linux (Ubuntu 20.04+, Debian 11+)
 CPU: 2+ núcleos
 RAM: 4GB mínimo (8GB recomendado)
 Disco: 10GB espacio libre
 Conexión de red: Estable
 Puertos a utilizar: 8080 (alias HTTP), 8443 (HTTPS), 5434 (PostgreSQL)
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

# Verificar instalación
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
git clone https://github.com/suorganizacion/aquadetection.git
cd aquadetection
chmod +x *.sh
```

---

## Configuración Inicial

### 1. Crear Archivo .env

```bash
# Crear desde plantilla
cp .env.example .env

# Editar configuración
nano .env
```

### 2. Contenido del .env (Esencial)

```bash
# ========== Configuración SSL/TLS ==========
DOMAIN_NAME=aquadetection.local
CERT_TYPE=self-signed          # 'self-signed' o 'letsencrypt'
EMAIL=admin@aquadetection.local       # Para Let's Encrypt
ALLOWED_IP=10.3.11.101         # IP para whitelist

# ========== Configuración de Base de Datos ==========
POSTGRES_DB=aquadetection_db
POSTGRES_USER=aquadetection_user
POSTGRES_PASSWORD=YourSecurePassword123!
DATABASE_URL=postgresql://aquadetection_user:YourSecurePassword123!@db:5432/aquadetection_db

# ========== Configuración de Backend ==========
SECRET_KEY=your-secret-key-change-me-in-production-minimum-32-chars-long
ENVIRONMENT=production          # 'development' o 'production'
LOG_LEVEL=INFO

# ========== Claves de API (Opcional pero recomendado) ==========
VIRUSTOTAL_API_KEY=your_virustotal_key_here
ABUSEIPDB_API_KEY=your_abuseipdb_key_here

# ========== Seguridad ==========
CORS_ORIGINS=https://aquadetection.local
SESSION_TIMEOUT=3600          # segundos
```

### 3. Configurar /etc/hosts

En su máquina local **Y** en el servidor (10.3.11.101):

```bash
sudo nano /etc/hosts

# Agregar estas líneas:
127.0.0.1       aquadetection.local
10.3.11.101     aquadetection.local
```

### 4. Verificar Configuración

```bash
# Validar archivo .env
grep "DOMAIN_NAME\|ALLOWED_IP\|SECRET_KEY" .env

# Verificar que no hay espacios extras
cat .env | grep "=" | head -5

# Probar conectividad
ping -c 3 10.3.11.101
curl -I https://10.3.11.101 2>/dev/null || echo "Esperado: conexión rechazada (todavía no iniciado)"
```

---

## Inicio del Sistema

### Opción 1: Inicio Rápido (Recomendado)

```bash
# Ir al directorio raíz
cd /ruta/a/aquadetection

# Iniciar todo
./start.sh

# Esperar 30-60 segundos para que se generen certificados
# Ver registros
docker-compose logs -f nginx

# Cuando vea: "nginx entered RUNNING state"
# El sistema está listo
```

### Opción 2: Inicio Manual con Docker Compose

```bash
# Construir imágenes (primera vez)
docker-compose build

# Iniciar servicios
docker-compose up -d

# Ver estado
docker-compose ps

# Ver registros
docker-compose logs -f
```

### Opción 3: Inicio con Script SSL Personalizado

```bash
chmod +x setup_ssl.sh malcom_ssl.sh

# Configurar SSL
./setup_ssl.sh

# Iniciar servicios SSL
./malcom_ssl.sh start

# Ver estado
./malcom_ssl.sh status

# Probar HTTPS
./malcom_ssl.sh test-https
```

### Verificar que Todo Está Funcionando

```bash
# Ver estado de servicios
docker-compose ps

# Debería mostrar:
# NAME          STATUS
# nginx         Up (healthy)
# frontend      Up
# backend       Up
# db            Up

# Verificar registros de Nginx
docker-compose logs nginx | tail -20

# Probar certificado SSL
openssl s_client -connect 10.3.11.101:443 -servername aquadetection.local < /dev/null

# Debería mostrar: "Verify return code: 18 (self signed certificate)"

# Probar acceso HTTPS
curl -k -I https://aquadetection.local/ 2>&1 | head -10

# Debería mostrar: "HTTP/2 200"
```

### Inicializar Base de Datos (Primera Vez)

```bash
# Ejecutar script de inicialización
docker-compose exec backend python init_db.py

# Resultado esperado:
#  Tables created successfully
#  Admin user created (admin/admin123)
#  Default user created (user/user123)
```

---

## Gestión de Usuarios

### Credenciales por Defecto

| Usuario | Contraseña | Rol | Descripción |
|---------|-----------|-----|-------------|
| `admin` | `admin123` | Admin | Acceso total al sistema |
| `user` | `user123` | User | Acceso limitado a escaneos |

 **CAMBIAR CONTRASEÑAS INMEDIATAMENTE DESPUÉS DEL PRIMER INICIO DE SESIÓN**

### Opción 1: Script Interactivo (Recomendado)

```bash
# Menú interactivo completo
./manage_users.sh

# Opciones:
# [1] Crear nuevo usuario
# [2] Listar todos los usuarios
# [3] Cambiar contraseña
# [4] Promover a administrador
# [5] Degradar de administrador
# [6] Eliminar usuario
# [7] Crear usuario rápido
```

### Opción 2: Script de Línea de Comandos

```bash
# Crear usuario regular
./quick_user.sh analyst1 secure_password

# Crear usuario rápido (contraseña = nombre de usuario)
./quick_user.sh analyst1

# Crear administrador
./quick_user.sh admin2 admin_pass admin
```

### Opción 3: Línea de Comandos Directa

```bash
# Acceder a shell del backend
docker-compose exec backend bash

# Crear usuario vía Python
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

### Gestión de Roles

```bash
# Promover usuario a administrador
./manage_users.sh  # Opción 4

# Degradar administrador a usuario regular
./manage_users.sh  # Opción 5

# Ver todos los usuarios y roles
./manage_users.sh  # Opción 2
```

---

## Uso del Sistema

### Acceso a la Aplicación

#### Vía Dominio (Recomendado)

```
https://aquadetection.local
```

#### Vía IP Directa

```
https://10.3.11.101
```

#### APIs de Backend

```
Documentación Swagger: https://aquadetection.local/api/v1/docs
ReDoc: https://aquadetection.local/api/v1/redoc
JSON OpenAPI: https://aquadetection.local/api/v1/openapi.json
```

### Inicio de Sesión

1. Abra https://aquadetection.local
2. Ingrese credenciales:
   - Usuario: `admin` o `user`
   - Contraseña: la contraseña asignada
3. Haga clic en "Iniciar Sesión"
4. Se generará token JWT válido por 1 hora

### Panel de Control Principal

**Para Administradores:**
- Panel de amenazas
- Escaneo de IPs, Hashes, Dominios
- Gestión de ransomware
- Gestión de usuarios
- Registros de auditoría
- Configuración del sistema

**Para Usuarios Regulares:**
- Panel simplificado
- Escaneo de amenazas
- Historial de análisis

### Escaneo de Amenazas

#### Análisis de Hash MD5/SHA256

```
1. Ir a "Security Engine" -> "Scan"
2. Seleccionar tipo: "File Hash"
3. Pegar hash: p. ej., d41d8cd98f00b204e9800998ecf8427e
4. Haga clic en "Analyze"
5. Resultados de VirusTotal, URLhaus, etc.
```

#### Análisis de IP

```
1. Ir a "Security Engine" -> "Scan"
2. Seleccionar tipo: "IP Address"
3. Ingresar IP: p. ej., 192.168.1.1
4. Haga clic en "Analyze"
5. Resultados de reputación de AbuseIPDB
```

#### Análisis de Dominio/URL

```
1. Ir a "Security Engine" -> "Scan"
2. Seleccionar tipo: "URL"
3. Ingresar URL: p. ej., https://example.com
4. Haga clic en "Analyze"
5. Resultados de VirusTotal y URLhaus
```

### Gestión de Ransomware

**Solo para Administradores:**

```
1. Ir a "Ransomware Manager"
2. Opciones:
   - Agregar nuevo IOC
   - Buscar IOCs existentes
   - Ver estadísticas
   - Eliminar IOC
```

### Ver Registros de Auditoría

**Solo para Administradores:**

```
1. Ir a "System Logs"
2. Filtrar por:
   - Usuario
   - Tipo de acción
   - Fecha
   - Resultado (exitoso/fallido)
3. Ver detalles completos de cada acción
```

---

## API REST Completa

### Autenticación

#### Obtener Token JWT

```bash
curl -X POST "https://aquadetection.local/api/v1/auth/login/access-token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123" \
  -k  # Ignorar certificado autofirmado
```

**Respuesta:**
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

### Puntos Finales de Escaneo

#### Escanear Hash (VirusTotal)

```bash
curl -X POST "https://aquadetection.local/api/v1/scan/hash" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"file_hash": "d41d8cd98f00b204e9800998ecf8427e"}' \
  -k
```

**Respuesta:**
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

### Puntos Finales de Usuarios (Administrador)

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

### Puntos Finales de Ransomware (Administrador)

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
curl -X GET "https://aquadetection.local/api/v1/ransomware/search?query=hash" \
  -H "Authorization: Bearer $TOKEN" \
  -k
```

### Documentación Interactiva

```
Swagger UI: https://aquadetection.local/api/v1/docs
ReDoc:      https://aquadetection.local/api/v1/redoc
```

---

## Seguridad Implementada

### 1. Autenticación

```
 JWT (Tokens Web JSON) con RS256
 Contraseñas procesadas con bcrypt (rounds=12)
 Expiración del token: 1 hora
 Capacidad de token de actualización
 Cierre de sesión / invalidación de token
```

### 2. Autorización (RBAC)

```
 Dos roles: Administrador y Usuario
 Puntos finales protegidos por rol
 Acceso granular a funciones
 Admin: Acceso total (usuarios, registros, configuración)
 User: Solo escaneos de amenazas
```

### 3. Encriptación TLS/SSL

```
 TLS 1.3 (y TLS 1.2 como alternativa)
 Certificados RSA 2048-bit
 Suite de cifrado: TLS_AES_256_GCM_SHA384
 Perfect Forward Secrecy (PFS)
 Staple OCSP
 HTTP/2 sobre TLS (h2)
```

### 4. Control de Acceso por Red

```
 IP Whitelist: Solo 10.3.11.101
 Implementado a nivel Nginx (geo block)
 Registros de intentos rechazados
 Protección contra DDoS (limitación de velocidad)
```

### 5. Encabezados de Seguridad

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Frame-Options: DENY                    # Evitar clickjacking
X-Content-Type-Options: nosniff          # Evitar MIME sniffing
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: default-src 'self'
```

### 6. Auditoría y Registro

```
 Registro de todos los inicios de sesión (exitosos y fallidos)
 Registro de cambios de usuarios
 Registro de acciones administrativas
 Registro de análisis/escaneos
 Marcas de tiempo e IP de origen
 Nivel de severidad (INFO, WARNING, ERROR)
 Registros no modificables (solo escritura)
```

### 7. Validación de Datos

```
 Modelos de Pydantic para verificación de tipos
 Sanitización de entrada
 Prevención de inyección SQL (ORM + consultas parametrizadas)
 Prevención de XSS (React + sanitización)
 Validación de token CSRF
```

### 8. Gestión de Certificados

```
 Certificados autofirmados para dev (RSA 2048, 1 año)
 CertBot para Let's Encrypt en producción
 Auto-renovación cada 60 días
 Reversión automática en caso de fallo de renovación
 Notificaciones de próximo vencimiento
```

### 9. Base de Datos

```
 PostgreSQL 15 con encriptación
 Conexiones solo desde Backend (no expuesta)
 Puerto: 5434 (no estándar)
 Usuario específico con permisos limitados
 Copias de seguridad automatizadas
```

### 10. Mejores Prácticas

```
 Variables sensibles en .env (no en código)
 Sin registro de contraseñas
 Limitación de velocidad en puntos finales críticos
 CORS restrictivo (solo aquadetection.local)
 Secretos no versionados en Git
 Principio de privilegio mínimo
```

---

## Implementación en la Nube

### Preparación para Producción

Antes de implementar, asegúrese de:

```bash
# 1. Cambiar todas las contraseñas por defecto
nano .env
# Editar: POSTGRES_PASSWORD, SECRET_KEY, contraseña de administrador

# 2. Configurar HTTPS con Let's Encrypt (no autofirmado)
CERT_TYPE=letsencrypt
EMAIL=your-email@yourdomain.com
DOMAIN_NAME=aquadetection.yourdomain.com

# 3. Actualizar IP whitelist
ALLOWED_IP=your.cloud.server.ip

# 4. Habilitar copias de seguridad
docker-compose exec db pg_dump -U aquadetection_user aquadetection_db > backup.sql

# 5. Configurar alertas y monitoreo
# Ver sección "Monitoreo"
```

### Opción 1: AWS EC2

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
# Apuntar su dominio a la IP Elástica de AWS
```

### Opción 2: Instancias de Contenedor de Azure

```bash
# 1. Crear grupo de contenedores
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

### Opción 3: GCP Compute Engine

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

### Configuración de Dominio

#### Con Let's Encrypt (Recomendado)

```bash
# CertBot se configura automáticamente en docker-compose.yml

# 1. Asegurar que el dominio está configurado en DNS
# 2. Asegurar que los puertos 80 y 443 están abiertos
# 3. En .env:
CERT_TYPE=letsencrypt
EMAIL=your-email@yourdomain.com
DOMAIN_NAME=aquadetection.yourdomain.com

# 4. Iniciar (CertBot generará certificados automáticamente)
docker-compose up -d

# 5. Verificar certificados
docker-compose logs certbot | tail -20

# 6. Los certificados se renuevan automáticamente
# Verificar próxima renovación
docker-compose exec nginx certbot renew --dry-run
```

#### Renovación de Certificados

```bash
# Manual
docker-compose exec nginx certbot renew

# Automático (trabajo cron, ejecutado cada día)
# Ya incluido en docker-compose.yml

# Verificar
docker-compose logs nginx | grep certbot
```

### Copias de Seguridad y Recuperación

```bash
# 1. Copia de seguridad de base de datos
docker-compose exec db pg_dump -U aquadetection_user aquadetection_db > aquadetection_backup_$(date +%Y%m%d).sql

# 2. Copia de seguridad de configuración
tar -czf aquadetection_config_$(date +%Y%m%d).tar.gz .env infrastructure/

# 3. Copiar a almacenamiento seguro (S3, Azure Blob, etc.)
aws s3 cp aquadetection_backup_*.sql s3://my-bucket/backups/

# 4. Restaurar desde copia de seguridad
docker-compose exec -T db psql -U aquadetection_user aquadetection_db < aquadetection_backup_20250126.sql
```

### Monitoreo y Alertas

```bash
# Ver registros en tiempo real
docker-compose logs -f

# Ver registros específicos
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
# - Errores en registros del backend
```

---

## Solución de Problemas

### Problema 1: "Error de Certificado SSL"

**Síntoma:** El navegador muestra "Su conexión no es privada"

**Causa Probable:** Certificado autofirmado en desarrollo

**Solución:**

```bash
# Opción 1: Ignorar advertencia
# Avanzado -> Ir a aquadetection.local (inseguro)

# Opción 2: Importar certificado como de confianza
docker-compose exec nginx cat /etc/letsencrypt/live/aquadetection.local/cert.pem > aquadetection.pem

# En macOS:
open aquadetection.pem
# Acceso a Cadena de Claves -> Siempre Confiar

# En Linux:
sudo cp aquadetection.pem /usr/local/share/ca-certificates/
sudo update-ca-certificates

# En Windows:
# Configuración -> Certificados -> Importar -> Raíz de Confianza
```

### Problema 2: "Conexión Rechazada" / No se puede acceder

**Síntoma:** `curl: (7) Failed to connect to aquadetection.local port 443`

**Verificar:**

```bash
# 1. Docker está ejecutándose
docker-compose ps

# 2. Nginx está UP
docker-compose logs nginx | tail -20

# 3. El puerto 443 está disponible
sudo lsof -i :443

# 4. El dominio está en /etc/hosts
cat /etc/hosts | grep aquadetection

# 5. El cortafuegos permite 443
sudo ufw allow 443
```

**Solución:**

```bash
# Reiniciar Nginx
docker-compose restart nginx

# Verificar configuración de Nginx
docker-compose exec nginx nginx -t

# Ver registros
docker-compose logs nginx
```

### Problema 3: "Dirección IP No Permitida"

**Síntoma:** Error `403 Forbidden`

**Causa:** IP no está en whitelist

**Solución:**

```bash
# 1. Verificar su IP actual
curl ifconfig.me

# 2. Actualizar .env con su IP
ALLOWED_IP=your.actual.ip.here

# 3. Verificar nginx.conf
docker-compose exec nginx cat /etc/nginx/nginx.conf | grep -A 5 "geo"

# 4. Recargar Nginx
docker-compose exec nginx nginx -s reload

# Alternativa: Deshabilitar whitelist temporalmente (SOLO desarrollo)
# Comentar línea "deny all" en nginx.conf
```

### Problema 4: Error de Conexión a Base de Datos

**Síntoma:** Backend no puede conectarse a PostgreSQL

**Solución:**

```bash
# 1. Verificar que PostgreSQL está ejecutándose
docker-compose ps db

# 2. Verificar credenciales en .env
grep DATABASE_URL .env

# 3. Conectarse directamente a BD
docker-compose exec db psql -U aquadetection_user -d aquadetection_db

# 4. Ver registros de BD
docker-compose logs db

# 5. Reiniciar BD
docker-compose restart db
```

### Problema 5: "Falta de Memoria"

**Síntoma:** Los contenedores de Docker se detienen sin motivo

**Solución:**

```bash
# Ver consumo de memoria
docker stats

# Reducir límites en docker-compose.yml
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

**Síntoma:** Página en blanco o "Cannot GET /"

**Solución:**

```bash
# 1. Verificar que frontend está ejecutándose
docker-compose ps frontend

# 2. Ver registros del frontend
docker-compose logs frontend

# 3. Verificar puerto 3000
docker-compose exec frontend curl localhost:3000

# 4. Verificar configuración de Nginx
docker-compose exec nginx cat /etc/nginx/conf.d/default.conf | grep -A 10 "location /"

# 5. Reconstruir frontend
docker-compose build frontend
docker-compose up -d frontend
```

### Problema 7: API Retorna 401/403

**Síntoma:** "Unauthorized" o "Forbidden"

**Verificar:**

```bash
# 1. Token válido
curl -X POST "https://aquadetection.local/api/v1/auth/login/access-token" \
  -d "username=admin&password=admin123" \
  -k

# 2. Token incluido en solicitud
curl -X GET "https://aquadetection.local/api/v1/users/me" \
  -H "Authorization: Bearer $TOKEN" \
  -k

# 3. Token expirado
# Token válido por 1 hora
# Obtener nuevo token

# 4. Usuario existe
./manage_users.sh  # Ver opción 2
```

### Problema 8: Certificado Próximo a Vencer

**Síntoma:** Advertencia en registros sobre certificado vencido

**Solución:**

```bash
# 1. Renovar manualmente
docker-compose exec nginx certbot renew

# 2. Ver próxima renovación
docker-compose exec nginx certbot certificates

# 3. Para Let's Encrypt:
# Se renueva automáticamente 30 días antes de vencer

# 4. Configurar alertas
# Agregar a crontab:
# 0 0 * * * certbot renew --email admin@yourdomain.com
```

### Problema 9: Rendimiento Lento

**Síntoma:** Respuestas lentas desde la API

**Optimizaciones:**

```bash
# 1. Verificar recursos disponibles
docker stats

# 2. Ver registros del backend
docker-compose logs backend | grep ERROR

# 3. Aumentar workers de Uvicorn
# En backend/main.py:
# uvicorn.run(..., workers=4)

# 4. Aumentar grupo de conexiones de PostgreSQL
# En docker-compose.yml env
SQLALCHEMY_POOL_SIZE=20
SQLALCHEMY_MAX_OVERFLOW=40

# 5. Cachear respuestas en Nginx
# nginx.conf:
# proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=api_cache:10m;

# 6. Habilitar compresión GZIP
# Ya habilitado en nginx.conf
# Verificar:
curl -I -H "Accept-Encoding: gzip" https://aquadetection.local/
# Debería mostrar: Content-Encoding: gzip
```

---

## Referencia Técnica

### Estructura de Carpetas

```
aquadetection/
+-- backend/
|   +-- app/
|   |   +-- api/           # Puntos finales REST
|   |   |   +-- auth.py
|   |   |   +-- logs.py
|   |   |   +-- ransomware.py
|   |   |   +-- scan.py
|   |   |   +-- users.py
|   |   +-- core/          # Configuración central
|   |   |   +-- config.py
|   |   |   +-- database.py
|   |   |   +-- encryption.py
|   |   |   +-- logging.py
|   |   |   +-- security.py
|   |   +-- models/        # Modelos de BD
|   |   |   +-- user.py
|   |   |   +-- ransomware.py
|   |   |   +-- audit_log.py
|   |   +-- services/      # Lógica de negocio
|   |       +-- scan_service.py
|   |       +-- audit.py
|   +-- main.py            # Punto de entrada
|   +-- init_db.py         # Inicialización BD
|   +-- Dockerfile         # Compilación backend
|   +-- requirements.txt    # Dependencias de Python
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
|   |   +-- App.tsx        # Componente raíz
|   |   +-- main.tsx       # Punto de entrada
|   +-- Dockerfile         # Compilación frontend
|   +-- package.json       # Dependencias npm
|   +-- vite.config.ts     # Configuración Vite
|   +-- tailwind.config.js # Configuración Tailwind
|
+-- infrastructure/
|   +-- nginx/
|       +-- Dockerfile     # Compilación de Nginx personalizado
|       +-- nginx.conf     # Configuración de Nginx
|       +-- init_certbot.sh # Script de inicialización de certificados
|       +-- renew_certs.sh # Script de renovación de certificados
|
+-- docker-compose.yml     # Orquestación de servicios
+-- .env.example          # Plantilla .env
+-- setup_ssl.sh          # Instalación inicial SSL
+-- malcom_ssl.sh         # Comandos SSL
+-- start.sh              # Iniciar sistema
+-- stop.sh               # Detener sistema
+-- manage_users.sh       # Gestión de usuarios interactiva
+-- quick_user.sh         # Crear usuario rápido
+-- README.md             # Este archivo
```

### Puertos en Uso

| Puerto | Servicio | Protocolo | Acceso | Descripción |
|--------|----------|-----------|--------|-------------|
| **8080** | Nginx | HTTP | Externo | Redirección a HTTPS (alias para puerto 80) |
| **8443** | Nginx | HTTPS | Externo (10.3.11.101) | Reverse proxy (alias para puerto 443) |
| **3000** | Frontend | HTTP | Interno | React (solo Docker) |
| **8000** | Backend | HTTP | Interno | FastAPI (solo Docker) |
| **5434** | PostgreSQL | TCP | Interno | Base de datos |

### Certificados SSL/TLS

```
Ubicación en Docker: /etc/letsencrypt/live/aquadetection.local/
+-- fullchain.pem  # Certificado + cadena
+-- privkey.pem    # Clave privada
+-- cert.pem       # Certificado
+-- chain.pem      # Cadena de autoridad

Volumen Docker: certbot_data
Renovación automática: Cada 60 días (Let's Encrypt)
Algoritmo: RSA 2048-bit
Protocolo: TLS 1.2, TLS 1.3
```

### Variables de Entorno Esenciales

```bash
# SSL/TLS
DOMAIN_NAME              # Dominio del sistema
CERT_TYPE               # 'self-signed' o 'letsencrypt'
EMAIL                   # Correo electrónico para Let's Encrypt
ALLOWED_IP              # IP whitelist

# Base de Datos
POSTGRES_USER           # Usuario PostgreSQL
POSTGRES_PASSWORD       # Contraseña de PostgreSQL
POSTGRES_DB             # Nombre de la base de datos
DATABASE_URL            # URL de conexión completa

# Backend
SECRET_KEY              # Clave para JWT (min 32 chars)
ENVIRONMENT             # 'development' o 'production'
LOG_LEVEL              # DEBUG, INFO, WARNING, ERROR

# APIs Externas
VIRUSTOTAL_API_KEY      # Clave de API VirusTotal
ABUSEIPDB_API_KEY       # Clave de API AbuseIPDB

# CORS
CORS_ORIGINS            # Orígenes permitidos
SESSION_TIMEOUT         # Tiempo de espera de sesión (segundos)
```

### Comandos Docker Útiles

```bash
# Ver registros en tiempo real
docker-compose logs -f [servicio]

# Ejecutar comando en contenedor
docker-compose exec [servicio] [comando]

# Reiniciar servicio
docker-compose restart [servicio]

# Reconstruir imagen
docker-compose build [servicio]

# Ver consumo de recursos
docker stats

# Copiar archivo del contenedor
docker-compose cp [servicio]:/ruta/archivo ./local/

# Ver volúmenes
docker volume ls
docker volume inspect aquadetection_certbot_data

# Limpiar todo
docker-compose down -v
```

### Scripts Disponibles

| Script | Propósito | Uso |
|--------|----------|-----|
| `start.sh` | Iniciar sistema | `./start.sh` |
| `stop.sh` | Detener sistema | `./stop.sh` |
| `setup_ssl.sh` | Configuración SSL inicial | `./setup_ssl.sh` |
| `malcom_ssl.sh` | Comandos SSL/gestión | `./malcom_ssl.sh [comando]` |
| `manage_users.sh` | Gestión de usuarios interactiva | `./manage_users.sh` |
| `quick_user.sh` | Crear usuario rápido | `./quick_user.sh [usuario] [pass] [admin]` |

### Solución Avanzada de Problemas

#### Verificar Certificado SSL

```bash
# Ver detalles del certificado
openssl x509 -in /ruta/a/cert.pem -text -noout

# Verificar certificado está en servidor
openssl s_client -connect aquadetection.local:443 -servername aquadetection.local

# Validar cadena de certificados
openssl verify -CAfile /ruta/a/chain.pem cert.pem

# Ver próxima fecha de vencimiento
openssl x509 -enddate -noout -in cert.pem
```

#### Verificar Configuración de Nginx

```bash
# Validar sintaxis
docker-compose exec nginx nginx -t

# Ver configuración cargada
docker-compose exec nginx nginx -T

# Ver puertos escuchando
docker-compose exec nginx netstat -tuln | grep LISTEN
```

#### Verificar Conectividad a Base de Datos

```bash
# Conectarse a PostgreSQL
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

## Soporte y Contacto

### Documentación Interna

- **Documentación de API Swagger:** https://aquadetection.local/api/v1/docs
- **ReDoc:** https://aquadetection.local/api/v1/redoc
- **JSON OpenAPI:** https://aquadetection.local/api/v1/openapi.json

### Registros y Depuración

```bash
# Registros centralizados
docker-compose logs -f

# Por servicio
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f nginx
docker-compose logs -f db

# Estadísticas
docker stats
```

### Reporte de Problemas

Incluir:
1. Salida de `docker-compose ps`
2. Salida de `docker-compose logs [servicio]`
3. Registros del navegador (F12)
4. Comando exacto que causa el problema
5. Salida esperada vs. real

---

## Registro de Cambios

### v2.0 (SSL/HTTPS Migration) - 26 de enero de 2025

**Nuevas Características:**
- Encriptación HTTPS/TLS 1.3
- Certificados SSL con CertBot
- IP Whitelist (10.3.11.101)
- Reverse proxy Nginx
- Encabezados de seguridad
- Protocolo HTTP/2
- Compresión GZIP
- Registro de auditoría completo
- Listo para implementación en la nube (AWS, Azure, GCP)

**Cambios Técnicos:**
- Migración de localhost a dominio `aquadetection.local`
- Puertos: 8082/8083 -> 80/443 (Nginx)
- Reestructuración de Docker Compose v2
- .env obligatorio para configuración
- Scripts de gestión mejorados

**Deprecaciones:**
- HTTP inseguro (localhost)
- Puertos 8082/8083

### v1.0 (Lanzamiento Inicial)

- Infraestructura base con Docker
- Backend FastAPI
- Frontend React
- Base de datos PostgreSQL
- Autenticación JWT
- Escaneo de amenazas
- Gestión de ransomware
- Registros de auditoría

---

**Hecho con dedicación para seguridad en la nube**

**Última Actualización:** 26 de enero de 2025

# 🌐 AcuaDetection - Sistema en Producción (Nube)

## ¿Qué cambió?

El sistema ahora está **100% listo para producción en la nube** con:

✅ **Dominios dinámicos**: Configura cualquier dominio que tengas  
✅ **Puerto 80 y 443**: Acceso estándar (no necesita puertos personalizados)  
✅ **Let's Encrypt integrado**: Obtiene certificados SSL automáticamente  
✅ **Certificados autofirmados fallback**: Para desarrollo/testing  
✅ **Detección automática**: .local → autofirmado, dominio real → Let's Encrypt  

## 🚀 Inicio Rápido (5 minutos)

### 1. Apunta tu DNS

```bash
# En tu proveedor DNS, crea:
A   tu-dominio.com   →  TU_IP_CLOUD
```

Espera 5-15 minutos para propagación.

### 2. Configura e inicia

```bash
# Opción A: Automático (te pregunta)
./start.sh

# Opción B: Variables de entorno
export DOMAIN_NAME="tu-dominio.com"
export EMAIL="tu-email@ejemplo.com"
./start.sh
```

### 3. Accede

```
https://tu-dominio.com    ← Tu aplicación
https://tu-dominio.com/api/v1/docs    ← Swagger
```

## 📋 Detalles Técnicos

### Configuración

**Archivo `.env` (se genera automáticamente):**

```bash
DOMAIN_NAME=tu-dominio.com              # Tu dominio
EMAIL=admin@tu-dominio.com              # Para Let's Encrypt
POSTGRES_PASSWORD=aquadetection_secure_pass
SECRET_KEY=tu-clave-secreta-fuerte
```

### Puertos Expuestos

```
Puerto 80  (HTTP)   →  Redirige a HTTPS
Puerto 443 (HTTPS)  →  Acceso seguro con certificado SSL
```

**NO hay puertos 8080 o 8443**. Acceso directo en puertos estándar.

### Certificados SSL

**Automático para dominios reales:**
```
dominio.com    → Intenta Let's Encrypt
tu-ip/         → Autofirmado (dev)
.local         → Autofirmado (dev)
```

**Let's Encrypt se obtiene automáticamente en el primer inicio si:**
- Dominio NO termina en `.local`
- Email es válido (formato: usuario@dominio.com)
- Puerto 80 es accesible desde internet
- DNS apunta correctamente

## 🔐 Certificados en Producción

### Renovación Automática

Let's Encrypt se renueva automáticamente 30 días antes del vencimiento:

```bash
# Verificar certificado
cd /etc/letsencrypt/live/tu-dominio.com
openssl x509 -in fullchain.pem -noout -dates
```

### Forzar renovación

```bash
docker compose exec nginx certbot renew --force-renewal
docker compose restart nginx
```

## 📊 Monitoreo

### Ver estado

```bash
docker compose ps                   # Estados de servicios
docker compose logs -f nginx        # Logs en tiempo real
curl https://tu-dominio.com/health  # Health check
```

### Verificar conexión desde internet

```bash
# Desde tu máquina local
curl https://tu-dominio.com

# O en navegador
https://tu-dominio.com
```

## 🔧 Solucionar Problemas

### "Certificate failed"
```bash
# 1. Verificar DNS
nslookup tu-dominio.com

# 2. Ver logs
docker compose logs nginx | grep cert

# 3. Fuerza autofirmado
sed -i 's/DOMAIN_NAME=.*/DOMAIN_NAME=localhost/' .env
./stop.sh && ./start.sh
```

### "Connection refused"
```bash
# Verificar que puertos están abiertos
sudo netstat -tlnp | grep -E ':80|:443'

# Verificar firewall
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### Backend no responde
```bash
docker compose logs backend
docker compose restart backend
```

## 📁 Estructura en Producción

```
/home/user/aquadetection/
├── .env                          # Configuración (gitignore)
├── docker-compose.yml            # Docker setup
├── start.sh                       # Iniciar
├── stop.sh                        # Parar
├── PRODUCTION.md                  # Esta guía
├── backend/
│   ├── main.py
│   ├── init_db.py
│   └── ...
├── frontend/
│   ├── src/
│   └── ...
└── infrastructure/
    └── nginx/
        ├── init_certbot.sh       # Certificados
        └── nginx.conf            # Configuración
```

## 🛡️ Recomendaciones de Seguridad

### 1. Firewall

```bash
# Permitir solo puertos necesarios
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP (Let's Encrypt)
sudo ufw allow 443/tcp     # HTTPS
sudo ufw enable
```

### 2. Contraseñas

```bash
# Cambiar contraseña admin AHORA
# Default: admin / admin123

# Accede a https://tu-dominio.com
# Login → Cambiar contraseña
```

### 3. SSL/TLS

```bash
# Verificar calidad SSL
curl --cert-status https://tu-dominio.com
# O visita: https://www.ssllabs.com/ssltest/
```

### 4. Backups

```bash
# Backup automático de BD diario
docker compose exec db pg_dump -U aquadetection aquadetection_db > backup_$(date +%Y%m%d).sql

# Restaurar
docker compose exec -T db psql -U aquadetection aquadetection_db < backup_20260127.sql
```

## 📈 Performance en Producción

### Optimizaciones recomendadas

1. **Caché**: Nginx ya tiene gzip activado
2. **CDN**: Coloca un CDN (CloudFlare) adelante
3. **Rate Limit**: Agrega nginx rate limiting si es necesario
4. **Database**: Aumentar conexiones PostgreSQL si necesario

### Escalabilidad

Para múltiples servidores:
1. Usa managed database (RDS, Azure Database)
2. Coloca Nginx como load balancer
3. Ejecuta múltiples instancias del backend

## 🔄 Actualizaciones

### Actualizar código

```bash
git pull
docker compose down
docker compose build
./start.sh
```

### Migrar datos

```bash
# Backup
docker compose exec db pg_dump -U aquadetection aquadetection_db > backup.sql

# Actualizar
git pull
docker compose down -v
./start.sh

# Restaurar si necesario
docker compose exec -T db psql -U aquadetection aquadetection_db < backup.sql
```

## 📞 Soporte

**Logs útiles:**
```bash
docker compose logs -f              # Todo
docker compose logs -f nginx        # Nginx/SSL
docker compose logs -f backend      # API
docker compose logs -f db           # Base de datos
```

**Verificar salud:**
```bash
curl https://tu-dominio.com/health
# Response: {"status":"healthy"}
```

---

**¡Tu sistema AcuaDetection está listo para producción! 🚀**

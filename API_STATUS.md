# Estado de las APIs de Detección de Amenazas

## APIs Operacionales

### 1. **AquaDetection** - Base de Datos Local de Ransomware
- **Estado**: [OK] OPERACIONAL
- **Función**: Verifica hashes, IPs y dominios contra la BD local
- **Respuesta**: Muestra "Malware encontrado en base de datos: [nombre]"
- **Categoría**: `malicious`
- **Uso**: Almacenar y verificar IOCs conocidos

### 2. **VirusTotal**
- **Estado**: [OK] OPERACIONAL
- **API Key**: `9cd240ab152139935d9939cda3227012904d247a5c426dc172930afc16500b36`
- **Motores**: 78+ antivirus engines
- **Tipos de búsqueda**: Hashes (MD5, SHA1, SHA256), URLs, Dominios, IPs
- **Respuesta**: Detalle de cada motor de detección
- **Categorías**: `malicious`, `suspicious`, `harmless`, `undetected`

### 3. **MalwareBazaar**
- **Estado**: [OK] OPERACIONAL
- **API Key**: `500429f6dc4dc035ff82953cfce889793e563fbc89a94729` [OK] Validada
- **Verificación**: Ejecutar `python3 backend/verify_malwarebazaar_key.py <API_KEY>`
- **Tipos de búsqueda**: Hashes (MD5, SHA1, SHA256)
- **Respuesta**: 
  - `query_status: ok` → Malware detectado (malicious)
  - `query_status: not_found` → No encontrado (harmless)
- **Autenticación**: Header `Auth-Key: <API_KEY>`

### 4. **MalShare**
- **Estado**: [OK] OPERACIONAL
- **API Key**: `11ccbe8e526aab052d6327b0b17ae44865a39323bbdabdcc61e4b9bf56616611`
- **Tipos de búsqueda**: Hashes (MD5, SHA1, SHA256)
- **Respuesta**: 
  - Encontrado → "Archivo Encontrado" (malicious)
  - No encontrado → "Limpio / No encontrado" (harmless)

### 5. **AbuseIPDB**
- **Estado**: [OK] OPERACIONAL
- **API Key**: `50cadad3d336deb9816697d07bbfc371f531830e326b7d08d1a5b68388e717f15cdeb37cd865507c`
- **Tipos de búsqueda**: Solo IPs
- **Respuesta**: Confidence score (%)
- **Categorías**: `malicious` (si score > 20%), `harmless`

## APIs Eliminadas

### HybridAnalysis
- **Razón**: Error HTTP 410 Gone (servicio deprecado)
- **Respuesta**: Siempre retornaba "410 Gone"

### PhishTank
- **Razón**: API inconsistente, poco confiable
- **Uso original**: Verificar URLs sospechosas

## Flujo de Escaneo

Cuando se escanea un objetivo (hash, IP, URL, dominio):

1. **Primero**: Verifica BD local (AquaDetection)
   - Si encontrado → Marca como malicioso
   
2. **Luego en paralelo**:
   - VirusTotal (si es aplicable)
   - MalwareBazaar (si es hash)
   - MalShare (si es hash)
   - AbuseIPDB (si es IP)

3. **Resultado final**:
   - Cuenta total de detecciones
   - Detalles de cada fuente
   - Categoría agregada (malicioso, sospechoso, seguro)

## Configuración (.env)

```env
# VirusTotal
VT_API_KEY=9cd240ab152139935d9939cda3227012904d247a5c426dc172930afc16500b36

# MalwareBazaar
MALWAREBAZAAR_API_KEY=500429f6dc4dc035ff82953cfce889793e563fbc89a94729

# MalShare
MALSHARE_API_KEY=11ccbe8e526aab052d6327b0b17ae44865a39323bbdabdcc61e4b9bf56616611

# AbuseIPDB
ABUSEIPDB_API_KEY=50cadad3d336deb9816697d07bbfc371f531830e326b7d08d1a5b68388e717f15cdeb37cd865507c
```

## Validación de APIs

### Verificar MalwareBazaar
```bash
python3 backend/verify_malwarebazaar_key.py "500429f6dc4dc035ff82953cfce889793e563fbc89a94729"
```

Resultado esperado:
```
[INFO] Verificando API key de MalwareBazaar...
[OK] API KEY VÁLIDA
```

## Métricas de Detección

Para un hash malicioso típico:
- **AquaDetection**: Detecta si está en BD local
- **VirusTotal**: 30-70 motores detectan (varía)
- **MalShare**: Detecta si está en su DB
- **MalwareBazaar**: Detecta si está registrado

Ejemplo de respuesta:
```json
{
  "summary": {
    "malicious": 58,
    "suspicious": 0,
    "harmless": 20,
    "undetected": 0
  }
}
```

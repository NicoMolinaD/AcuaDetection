import os
import re
import json
import httpx
import hashlib
import asyncio
from app.core.config import settings
from app.core.logging import get_logger
from app.core.exceptions import MalcomException

logger = get_logger(__name__)

class ScanService:
    def __init__(self):
        self.headers = {'User-Agent': 'AntigravityThreatDashboard/2.0'}

    def identify_hash_type(self, target: str) -> str:
        if not target:
            return "unknown"
        if re.match(r"^[a-fA-F0-9]{32}$", target): return "MD5"
        if re.match(r"^[a-fA-F0-9]{40}$", target): return "SHA1"
        if re.match(r"^[a-fA-F0-9]{64}$", target): return "SHA256"
        
        ip_pattern = r"^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
        if re.match(ip_pattern, target): return "IP"
        
        if "://" in target or "/" in target: return "URL"
        
        domain_pattern = r"^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$"
        if re.match(domain_pattern, target): return "Domain"
        
        if "." in target: return "Domain"
        return "unknown"

    async def check_virustotal(self, target: str, target_type: str):
        if not settings.VT_API_KEY: 
            return [{"source": "VirusTotal", "engine": "Scanner", "result": "Clave API no configurada", "category": "info"}]
        
        endpoint = "files"
        target_id = target
        if target_type == "URL":
            endpoint = "urls"
            import base64
            target_id = base64.urlsafe_b64encode(target.encode()).decode().strip("=")
        elif target_type == "Domain": endpoint = "domains"
        elif target_type == "IP": endpoint = "ip_addresses"

        url = f"https://www.virustotal.com/api/v3/{endpoint}/{target_id}"
        headers = {**self.headers, 'x-apikey': settings.VT_API_KEY}
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(url, headers=headers)
                if response.status_code == 200:
                    data = response.json()
                    attr = data.get('data', {}).get('attributes', {})
                    results = attr.get('last_analysis_results', {})
                    
                    detailed = []
                    for engine, res in results.items():
                        cat = res.get('category', 'harmless')
                        if cat == 'undetected': cat = 'harmless'
                        result_text = res.get('result') or 'Clean'
                        detailed.append({
                            "source": "VirusTotal", "engine": engine, 
                            "result": result_text, "category": cat
                        })
                    return detailed
                elif response.status_code == 404:
                    return [{"source": "VirusTotal", "engine": "Scanner", "result": "No encontrado", "category": "harmless"}]
        except Exception as e:
            logger.error(f"VT Error: {e}")
        return [{"source": "VirusTotal", "engine": "Scanner", "result": "Error de conexión", "category": "info"}]

    async def check_hybrid_analysis(self, target: str, target_type: str):
        if not settings.HA_API_KEY:
            return [{"source": "HybridAnalysis", "engine": "Sandbox", "result": "Clave API no configurada", "category": "info"}]
        if target_type not in ["MD5", "SHA1", "SHA256"]:
            return []
            
        url = "https://hybrid-analysis.com/api/v2/search/hash"
        headers = {**self.headers, 'api-key': settings.HA_API_KEY}
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(url, headers=headers, data={'hash': target})
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list) and data:
                        res = data[0]
                        verdict = res.get('verdict', 'Clean')
                        return [{
                            "source": "HybridAnalysis", 
                            "engine": "Sandbox", 
                            "result": f"Score: {res.get('threat_score', 0)}", 
                            "category": "malicious" if verdict in ["malicious", "suspicious"] else "harmless"
                        }]
                    return [{"source": "HybridAnalysis", "engine": "Sandbox", "result": "Limpio / No encontrado", "category": "harmless"}]
        except Exception as e:
            logger.error(f"HA Error: {e}")
        return [{"source": "HybridAnalysis", "engine": "Sandbox", "result": "Error", "category": "info"}]

    async def check_abuseipdb(self, target: str, target_type: str):
        if not settings.ABUSEIPDB_API_KEY:
             return [{"source": "AbuseIPDB", "engine": "IP Reputation", "result": "Clave API no configurada", "category": "info"}]
        if target_type != "IP": return []
        
        url = "https://api.abuseipdb.com/api/v2/check"
        params = {'ipAddress': target, 'maxAgeInDays': '90'}
        headers = {**self.headers, 'Key': settings.ABUSEIPDB_API_KEY, 'Accept': 'application/json'}
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(url, headers=headers, params=params)
                if response.status_code == 200:
                    data = response.json().get('data', {})
                    score = data.get('abuseConfidenceScore', 0)
                    return [{
                        "source": "AbuseIPDB", 
                        "engine": "IP Reputation", 
                        "result": f"Confidence: {score}%", 
                        "category": "malicious" if score > 20 else "harmless"
                    }]
        except Exception as e:
            logger.error(f"AbuseIPDB Error: {e}")
        return [{"source": "AbuseIPDB", "engine": "IP Reputation", "result": "Error", "category": "info"}]

    async def check_malwarebazaar(self, target: str, target_type: str):
        if not settings.MALWAREBAZAAR_API_KEY:
            return [{"source": "MalwareBazaar", "engine": "Database", "result": "Clave API no configurada", "category": "info"}]
        if target_type not in ["MD5", "SHA1", "SHA256"]: return []
        
        url = "https://mb-api.abuse.ch/api/v1/"
        data = {'query': 'get_info', 'hash': target}
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(url, data=data)
                if response.status_code == 200:
                    res = response.json()
                    if res.get('query_status') == 'ok':
                        return [{
                            "source": "MalwareBazaar", 
                            "engine": "Database", 
                            "result": "Malicioso Detectado", 
                            "category": "malicious"
                        }]
                    return [{"source": "MalwareBazaar", "engine": "Database", "result": "Limpio / No encontrado", "category": "harmless"}]
        except Exception as e:
            logger.error(f"MalwareBazaar Error: {e}")
        return [{"source": "MalwareBazaar", "engine": "Database", "result": "Error", "category": "info"}]

    async def check_malshare(self, target: str, target_type: str):
        if not settings.MALSHARE_API_KEY:
            return [{"source": "MalShare", "engine": "Database", "result": "Clave API no configurada", "category": "info"}]
        if target_type not in ["MD5", "SHA1", "SHA256"]: return []
        
        url = f"https://malshare.com/api.php?api_key={settings.MALSHARE_API_KEY}&action=details&hash={target}"
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(url)
                if response.status_code == 200:
                    data = response.json()
                    if data and not data.get('error'):
                        return [{
                            "source": "MalShare", "engine": "Database", "result": "Archivo Encontrado", "category": "malicious"
                        }]
                    return [{"source": "MalShare", "engine": "Database", "result": "Limpio / No encontrado", "category": "harmless"}]
        except Exception as e:
             logger.error(f"MalShare Error: {e}")
        return [{"source": "MalShare", "engine": "Database", "result": "Error", "category": "info"}]

    async def check_phishtank(self, target: str, target_type: str):
        if target_type != "URL": return []
        url = "https://checkurl.phishtank.com/checkurl/"
        data = {'url': target, 'format': 'json'}
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(url, data=data)
                if response.status_code == 200:
                    res = response.json().get('results', {})
                    if res.get('in_database'):
                        return [{
                            "source": "PhishTank", "engine": "Phishing Detector", "result": "URL Maliciosa", "category": "malicious"
                        }]
                    return [{"source": "PhishTank", "engine": "Phishing Detector", "result": "Limpio", "category": "harmless"}]
        except Exception as e:
            logger.error(f"PhishTank Error: {e}")
        return [{"source": "PhishTank", "engine": "Phishing Detector", "result": "No disponible", "category": "info"}]

    async def scan_target(self, target: str, filename: str = None):
        target_type = self.identify_hash_type(target)
        
        tasks = [
            self.check_virustotal(target, target_type),
            self.check_hybrid_analysis(target, target_type),
            self.check_abuseipdb(target, target_type),
            self.check_malwarebazaar(target, target_type),
            self.check_malshare(target, target_type),
            self.check_phishtank(target, target_type)
        ]
        
        results = await asyncio.gather(*tasks)
        
        # Flatten all detailed results
        all_details = []
        for r in results:
            if r:
                all_details.extend(r)
            
        malicious = sum(1 for r in all_details if r['category'] == 'malicious')
        suspicious = sum(1 for r in all_details if r['category'] == 'suspicious')
        harmless = sum(1 for r in all_details if r['category'] == 'harmless')
        
        # Ensure at least one result per source for UI visibility if keys exist
        sources_expected = {
            "VirusTotal": settings.VT_API_KEY,
            "HybridAnalysis": settings.HA_API_KEY,
            "AbuseIPDB": settings.ABUSEIPDB_API_KEY,
            "MalwareBazaar": settings.MALWAREBAZAAR_API_KEY,
            "MalShare": settings.MALSHARE_API_KEY,
            "PhishTank": True # Free
        }
        
        present_sources = {r['source'] for r in all_details}
        for source, key in sources_expected.items():
            if source not in present_sources:
                res_text = "No aplicable" if key else "Clave no configurada"
                all_details.append({
                    "source": source, "engine": "Scanner", "result": res_text, "category": "info"
                })

        has_real_config = any([settings.VT_API_KEY, settings.HA_API_KEY, settings.ABUSEIPDB_API_KEY])
        if not all_details or (malicious == 0 and suspicious == 0 and harmless == 0 and not has_real_config):
            return self.generate_mock_response(target, target_type, filename)
        
        return {
            "summary": {
                "malicious": malicious, 
                "suspicious": suspicious, 
                "harmless": harmless,
                "undetected": 0
            },
            "scans": all_details,
            "mode": "live",
            "target": target,
            "target_type": target_type
        }

    def generate_mock_response(self, target: str, target_type: str, filename: str = None):
        risk_score = 0
        
        safe_extensions = ['.png', '.jpg', '.jpeg', '.gif', '.pdf', '.txt', '.csv', '.bmp', '.svg']
        target_to_check = filename or target
        if any(target_to_check.lower().endswith(ext) for ext in safe_extensions):
            risk_score = 0
        elif target in ['127.0.0.1', '8.8.8.8']: risk_score = 0
        elif "test" in target or "virus" in target: risk_score = 90
        elif target_type in ["MD5", "SHA1", "SHA256"]: 
            if target:
                 seed = sum(ord(c) for c in target)
                 risk_score = seed % 100
        
        malicious = 0
        if risk_score > 50: malicious = int(risk_score / 10)
        
        scans = [
            {"source": "VirusTotal", "engine": "Scanner", "result": "Detected" if malicious > 5 else "Clean", "category": "malicious" if malicious > 5 else "harmless"},
            {"source": "HybridAnalysis", "engine": "Sandbox", "result": f"Score {risk_score}", "category": "malicious" if risk_score > 70 else "harmless"},
            {"source": "MalwareBazaar", "engine": "DB", "result": "Found" if malicious > 3 else "Not Found", "category": "malicious" if malicious > 3 else "harmless"},
            {"source": "MalShare", "engine": "DB", "result": "Found" if malicious > 2 else "Not Found", "category": "malicious" if malicious > 2 else "harmless"}
        ]
        
        return {
            "summary": {"malicious": malicious, "suspicious": 0, "harmless": 20, "undetected": 0},
            "scans": scans,
            "mode": "demo",
            "target": target,
            "target_type": target_type
        }

scan_service = ScanService()

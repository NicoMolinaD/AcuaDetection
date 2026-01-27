from fastapi import APIRouter, Depends, status
from typing import List, Dict, Any
import random
import hashlib

from app.api import deps
from app.models.user import User
from app.core.logging import get_logger
from app.core.exceptions import MalcomException

logger = get_logger(__name__)
router = APIRouter()

@router.get("/", response_model=Dict[str, Any])
def get_malcom_traffic(
    target: str = "target",
    is_malicious: bool = False,
    current_user: User = Depends(deps.get_current_user)
):
    target_seed = hashlib.md5(target.encode()).hexdigest()
    rng = random.Random(target_seed)

    nodes = [
        {"id": "source", "type": "source", "label": "Internal Network", "risk_score": 0},
        {"id": "target", "type": "malware" if is_malicious else "destination", "label": target, "risk_score": 90 if is_malicious else 10}
    ]
    
    links = [
        {"source": "source", "target": "target", "protocol": "TCP", "port": 443}
    ]
    
    # Generate a full spectrum of connections (15-20 nodes)
    num_nodes = rng.randint(15, 20)
    for i in range(1, num_nodes + 1):
        node_id = f"node_{i}"
        # Some nodes are more likely to be malicious if the target is malicious
        is_node_malicious = is_malicious and rng.random() > 0.6
        
        # Vary the labels to look like a mix of internal and external IPs
        if rng.random() > 0.4:
            # Random external-ish IP
            label = f"{rng.randint(45, 190)}.{rng.randint(1, 254)}.{rng.randint(1, 254)}.{rng.randint(1, 254)}"
        else:
            # Internal-ish IP
            label = f"192.168.1.{rng.randint(2, 254)}"

        nodes.append({
            "id": node_id,
            "type": "malware" if is_node_malicious else "destination",
            "label": label,
            "risk_score": rng.randint(70, 95) if is_node_malicious else rng.randint(0, 15)
        })
        
        # Add primary link from target to this node
        links.append({
            "source": "target",
            "target": node_id,
            "protocol": rng.choice(["TCP", "UDP", "HTTP", "HTTPS", "DNS", "SMB", "FTP", "SSH"]),
            "port": rng.choice([80, 443, 8080, 53, 22, 445, 21, 3389, 161])
        })

        # Occasionally add secondary links between nodes for a "web" effect (spectrum)
        if rng.random() > 0.85 and len(nodes) > 4:
            random_neighbor_idx = rng.randint(2, len(nodes) - 2)
            random_neighbor = nodes[random_neighbor_idx]["id"]
            if random_neighbor != node_id:
                links.append({
                    "source": node_id,
                    "target": random_neighbor,
                    "protocol": "TCP",
                    "port": rng.choice([443, 80, 8080])
                })

    return {
        "nodes": nodes,
        "links": links,
        "stats": {
            "total_connections": len(links),
            "malicious_hits": sum(1 for n in nodes if n["type"] == "malware"),
            "bytes_transferred": f"{rng.randint(10, 500)} KB"
        }
    }

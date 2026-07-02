#!/usr/bin/env python3
"""
seed.py — Alimente la base Inventra avec des données de démonstration.
Usage : DATABASE_URL=postgresql://... python seed.py
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))

os.environ.setdefault("DATABASE_URL", "sqlite:///inventra_dev.db")

from app import app
from models import db, Product, StockAlert

PRODUCTS = [
    dict(name="Écran 27\" Full HD",   category="Informatique",  sku="ECR-27FHD",  quantity=12,  price=189.99, alert_threshold=5,  unit="pièce"),
    dict(name="Clavier mécanique",    category="Informatique",  sku="CLV-MEC",    quantity=8,   price=79.90,  alert_threshold=10, unit="pièce"),
    dict(name="Souris ergonomique",   category="Informatique",  sku="SOU-ERG",    quantity=3,   price=49.99,  alert_threshold=5,  unit="pièce"),
    dict(name="Câble HDMI 2m",        category="Câblerie",      sku="CAB-HDMI2",  quantity=45,  price=8.50,   alert_threshold=10, unit="pièce"),
    dict(name="Switch 8 ports",       category="Réseau",        sku="SWT-8P",     quantity=4,   price=59.00,  alert_threshold=3,  unit="pièce"),
    dict(name="Patch cable Cat6 1m",  category="Réseau",        sku="CAB-CAT6-1", quantity=120, price=2.90,   alert_threshold=20, unit="pièce"),
    dict(name="Papier A4 80g (rame)", category="Fournitures",   sku="PAP-A4-80",  quantity=6,   price=4.20,   alert_threshold=15, unit="rame"),
    dict(name="Stylos bille noir",    category="Fournitures",   sku="STY-BNR",    quantity=0,   price=0.60,   alert_threshold=20, unit="pièce"),
    dict(name="Rallonge 5 prises",    category="Électricité",   sku="ELT-RL5",    quantity=9,   price=14.90,  alert_threshold=5,  unit="pièce"),
    dict(name="Lampe de bureau LED",  category="Mobilier",      sku="LAM-BUR",    quantity=2,   price=34.00,  alert_threshold=3,  unit="pièce"),
]

with app.app_context():
    db.create_all()
    if Product.query.count() > 0:
        print("La base contient déjà des données — seed ignoré.")
        sys.exit(0)

    for data in PRODUCTS:
        p = Product(**data)
        db.session.add(p)
    db.session.flush()

    # Créer les alertes pour les produits sous seuil
    for p in Product.query.all():
        if p.quantity <= p.alert_threshold:
            severity = "critical" if p.quantity == 0 else "warning"
            db.session.add(StockAlert(
                product_id=p.id,
                severity=severity,
                message=(
                    f"Rupture de stock : {p.name}"
                    if p.quantity == 0
                    else f"Stock bas : {p.name} ({p.quantity} {p.unit}(s) — seuil {p.alert_threshold})"
                )
            ))

    db.session.commit()
    print(f"✅ {Product.query.count()} produits et {StockAlert.query.filter_by(resolved=False).count()} alertes insérés.")

"""
Inventra — API REST de gestion de stocks.
Backend Flask + SQLAlchemy, base de données PostgreSQL.

En développement local : utilise SQLite (variable d'env DATABASE_URL absente).
En production AWS     : se connecte à RDS via DATABASE_URL injectée par Terraform
                        depuis AWS Secrets Manager / Parameter Store.
"""
import os
import logging
from flask import Flask, jsonify, request
from flask_cors import CORS
from models import db, Product, StockAlert

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  # Autorise les appels cross-origin du frontend (même VPC, mais ports différents)

# ── Configuration base de données ─────────────────────────────────────
DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "sqlite:///inventra_dev.db"   # fallback local pour les tests
)
# SQLAlchemy attend postgresql:// mais psycopg2 peut recevoir postgres://
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

app.config["SQLALCHEMY_DATABASE_URI"] = DATABASE_URL
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", "dev-secret-change-in-prod")

db.init_app(app)

with app.app_context():
    db.create_all()
    logger.info("Base de données initialisée : %s", DATABASE_URL.split("@")[-1])


# ── Health check ──────────────────────────────────────────────────────
@app.get("/health")
def health():
    try:
        db.session.execute(db.text("SELECT 1"))
        db_status = "ok"
    except Exception as e:
        db_status = f"error: {e}"
    return jsonify({
        "status": "ok" if db_status == "ok" else "degraded",
        "database": db_status,
        "version": "1.0.0",
    }), 200 if db_status == "ok" else 503


# ── Produits ──────────────────────────────────────────────────────────
@app.get("/api/products")
def list_products():
    """Liste tous les produits avec filtre optionnel sur la catégorie et le statut d'alerte."""
    category   = request.args.get("category")
    low_stock  = request.args.get("low_stock", "").lower() == "true"

    query = Product.query
    if category:
        query = query.filter_by(category=category)
    if low_stock:
        # Produits en dessous du seuil d'alerte
        query = query.filter(Product.quantity <= Product.alert_threshold)

    products = query.order_by(Product.name).all()
    return jsonify([p.to_dict() for p in products]), 200


@app.get("/api/products/<int:product_id>")
def get_product(product_id):
    product = db.get_or_404(Product, product_id)
    return jsonify(product.to_dict()), 200


@app.post("/api/products")
def create_product():
    data = request.get_json(silent=True) or {}
    name = (data.get("name") or "").strip()
    if not name:
        return jsonify({"error": "Le champ 'name' est requis"}), 400

    try:
        quantity        = int(data.get("quantity", 0))
        alert_threshold = int(data.get("alert_threshold", 10))
        price           = float(data.get("price", 0.0))
    except (ValueError, TypeError):
        return jsonify({"error": "Valeurs numériques invalides"}), 400

    product = Product(
        name            = name,
        description     = (data.get("description") or "").strip(),
        category        = (data.get("category") or "Général").strip(),
        quantity        = quantity,
        unit            = (data.get("unit") or "unité").strip(),
        price           = price,
        alert_threshold = alert_threshold,
        sku             = (data.get("sku") or "").strip() or None,
    )
    db.session.add(product)
    db.session.commit()
    _check_and_create_alert(product)
    logger.info("Produit créé : %s (id=%s)", product.name, product.id)
    return jsonify(product.to_dict()), 201


@app.put("/api/products/<int:product_id>")
def update_product(product_id):
    product = db.get_or_404(Product, product_id)
    data    = request.get_json(silent=True) or {}

    for field in ("name", "description", "category", "unit", "sku"):
        if field in data:
            setattr(product, field, (str(data[field]) or "").strip())
    for field in ("quantity", "alert_threshold"):
        if field in data:
            setattr(product, field, int(data[field]))
    if "price" in data:
        product.price = float(data["price"])

    db.session.commit()
    _check_and_create_alert(product)
    return jsonify(product.to_dict()), 200


@app.delete("/api/products/<int:product_id>")
def delete_product(product_id):
    product = db.get_or_404(Product, product_id)
    StockAlert.query.filter_by(product_id=product.id).delete()
    db.session.delete(product)
    db.session.commit()
    return "", 204


# ── Mouvement de stock ────────────────────────────────────────────────
@app.post("/api/products/<int:product_id>/move")
def move_stock(product_id):
    """Entrée (type=in) ou sortie (type=out) de stock."""
    product = db.get_or_404(Product, product_id)
    data    = request.get_json(silent=True) or {}

    move_type = data.get("type", "").lower()
    if move_type not in ("in", "out"):
        return jsonify({"error": "type doit être 'in' ou 'out'"}), 400

    try:
        qty = int(data.get("quantity", 0))
        if qty <= 0:
            raise ValueError
    except (ValueError, TypeError):
        return jsonify({"error": "quantity doit être un entier strictement positif"}), 400

    if move_type == "in":
        product.quantity += qty
    else:
        if product.quantity < qty:
            return jsonify({
                "error": f"Stock insuffisant : {product.quantity} disponible(s), {qty} demandé(s)"
            }), 409
        product.quantity -= qty

    db.session.commit()
    _check_and_create_alert(product)
    return jsonify(product.to_dict()), 200


# ── Alertes ───────────────────────────────────────────────────────────
@app.get("/api/alerts")
def list_alerts():
    """Alertes actives (non résolues) triées par sévérité."""
    alerts = (StockAlert.query
              .filter_by(resolved=False)
              .order_by(StockAlert.created_at.desc())
              .all())
    return jsonify([a.to_dict() for a in alerts]), 200


@app.put("/api/alerts/<int:alert_id>/resolve")
def resolve_alert(alert_id):
    alert = db.get_or_404(StockAlert, alert_id)
    alert.resolved = True
    db.session.commit()
    return jsonify(alert.to_dict()), 200


# ── Statistiques ──────────────────────────────────────────────────────
@app.get("/api/stats")
def stats():
    total_products = Product.query.count()
    low_stock      = Product.query.filter(
        Product.quantity <= Product.alert_threshold).count()
    out_of_stock   = Product.query.filter(Product.quantity == 0).count()
    active_alerts  = StockAlert.query.filter_by(resolved=False).count()

    # Valeur totale du stock
    products   = Product.query.all()
    total_value = sum(p.quantity * p.price for p in products)

    # Catégories distinctes
    categories = sorted({p.category for p in products if p.category})

    return jsonify({
        "total_products" : total_products,
        "low_stock"      : low_stock,
        "out_of_stock"   : out_of_stock,
        "active_alerts"  : active_alerts,
        "total_value"    : round(total_value, 2),
        "categories"     : categories,
    }), 200


# ── Helpers internes ──────────────────────────────────────────────────
def _check_and_create_alert(product: Product):
    """Crée ou supprime une alerte de stock bas selon le seuil."""
    existing = StockAlert.query.filter_by(
        product_id=product.id, resolved=False).first()

    if product.quantity <= product.alert_threshold:
        if not existing:
            severity = "critical" if product.quantity == 0 else "warning"
            alert = StockAlert(
                product_id = product.id,
                message    = (
                    f"Rupture de stock : {product.name}"
                    if product.quantity == 0
                    else f"Stock bas : {product.name} "
                         f"({product.quantity} {product.unit}(s) — seuil {product.alert_threshold})"
                ),
                severity   = severity,
            )
            db.session.add(alert)
            db.session.commit()
            logger.warning("Alerte créée pour %s (qty=%s)", product.name, product.quantity)
    else:
        if existing:
            existing.resolved = True
            db.session.commit()


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=False)

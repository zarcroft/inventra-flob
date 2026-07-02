"""
Modèles SQLAlchemy pour Inventra.
Compatible PostgreSQL (production RDS) et SQLite (développement local).
"""
from datetime import datetime, timezone
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


class Product(db.Model):
    __tablename__ = "products"

    id              = db.Column(db.Integer,     primary_key=True)
    name            = db.Column(db.String(200),  nullable=False)
    description     = db.Column(db.Text,         nullable=True)
    category        = db.Column(db.String(100),  nullable=False, default="Général")
    sku             = db.Column(db.String(100),  unique=True, nullable=True)
    quantity        = db.Column(db.Integer,      nullable=False, default=0)
    unit            = db.Column(db.String(50),   nullable=False, default="unité")
    price           = db.Column(db.Float,        nullable=False, default=0.0)
    alert_threshold = db.Column(db.Integer,      nullable=False, default=10)
    created_at      = db.Column(db.DateTime,     default=lambda: datetime.now(timezone.utc))
    updated_at      = db.Column(db.DateTime,     default=lambda: datetime.now(timezone.utc),
                                onupdate=lambda: datetime.now(timezone.utc))

    alerts = db.relationship("StockAlert", backref="product", lazy=True)

    def to_dict(self):
        return {
            "id"              : self.id,
            "name"            : self.name,
            "description"     : self.description or "",
            "category"        : self.category,
            "sku"             : self.sku or "",
            "quantity"        : self.quantity,
            "unit"            : self.unit,
            "price"           : self.price,
            "alert_threshold" : self.alert_threshold,
            "low_stock"       : self.quantity <= self.alert_threshold,
            "out_of_stock"    : self.quantity == 0,
            "created_at"      : self.created_at.isoformat() if self.created_at else None,
            "updated_at"      : self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self):
        return f"<Product {self.name!r} qty={self.quantity}>"


class StockAlert(db.Model):
    __tablename__ = "stock_alerts"

    id         = db.Column(db.Integer,    primary_key=True)
    product_id = db.Column(db.Integer,    db.ForeignKey("products.id"), nullable=False)
    message    = db.Column(db.Text,       nullable=False)
    severity   = db.Column(db.String(20), nullable=False, default="warning")  # warning | critical
    resolved   = db.Column(db.Boolean,   nullable=False, default=False)
    created_at = db.Column(db.DateTime,   default=lambda: datetime.now(timezone.utc))

    def to_dict(self):
        return {
            "id"           : self.id,
            "product_id"   : self.product_id,
            "product_name" : self.product.name if self.product else "?",
            "message"      : self.message,
            "severity"     : self.severity,
            "resolved"     : self.resolved,
            "created_at"   : self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f"<StockAlert product_id={self.product_id} severity={self.severity}>"
